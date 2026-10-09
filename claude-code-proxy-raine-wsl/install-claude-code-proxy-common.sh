#!/usr/bin/env bash

SERVICE_NAME=claude-code-proxy
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
DROPIN_DIR="/etc/systemd/system/${SERVICE_NAME}.service.d"
MANAGED_DROPIN="${DROPIN_DIR}/zz-claude-code-proxy-managed.conf"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE_PATH="${SCRIPT_DIR}/${SERVICE_NAME}.service.in"
LAUNCHER_SOURCE="${SCRIPT_DIR}/claude-code-proxy-launcher.sh"
LAUNCHER_PATH=/usr/local/libexec/claude-code-proxy-launcher
LEGACY_PROXY_URL=http://10.220.69.222:1088
DEFAULT_PROXY_URL=$LEGACY_PROXY_URL
NO_PROXY_LIST=${CCP_NO_PROXY:-localhost,127.0.0.1,server.teleport.zetyun.cn}

usage() {
    printf '用法: sudo %s [服务用户 [代理可执行文件绝对路径 [出站代理 URL]]]\n' "$0" >&2
    printf '默认值: server /home/server/.local/bin/claude-code-proxy %s\n' "$DEFAULT_PROXY_URL" >&2
    printf '代理选项: 1) %s  2) 默认网关 IP:8889  3) 自定义 URL\n' "$LEGACY_PROXY_URL" >&2
}

fail() {
    printf '错误: %s\n' "$1" >&2
    exit 1
}

[[ $# -le 3 ]] || { usage; exit 2; }
[[ ${EXPECTED_OS:-} == rocky || ${EXPECTED_OS:-} == ubuntu ]] || fail '请运行对应发行版的安装脚本。'
[[ $(id -u) -eq 0 ]] || fail '请使用 sudo 运行此安装脚本。'
[[ -r /etc/os-release ]] || fail '无法读取 /etc/os-release。'
# shellcheck disable=SC1091
. /etc/os-release
if [[ $EXPECTED_OS == rocky ]]; then
    [[ ${ID:-} == rocky && ( ${VERSION_ID:-} == 8 || ${VERSION_ID:-} == 8.* ) ]] || fail '此脚本仅适用于 Rocky Linux 8。'
else
    [[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 24.04 ]] || fail '此脚本仅适用于 Ubuntu 24.04。'
fi

command -v systemctl >/dev/null 2>&1 || fail '未找到 systemctl。'
[[ -d /run/systemd/system ]] || fail '当前系统未由 systemd 启动。'
[[ -r $TEMPLATE_PATH ]] || fail "找不到 unit 模板: $TEMPLATE_PATH"
[[ -r $LAUNCHER_SOURCE ]] || fail "找不到启动器: $LAUNCHER_SOURCE"

SERVICE_USER=${1:-server}
PROXY_BIN=${2:-"/home/${SERVICE_USER}/.local/bin/claude-code-proxy"}
PROXY_URL=${3:-$DEFAULT_PROXY_URL}
if [[ -t 0 && $# -eq 0 ]]; then
    read -r -p "服务用户 [$SERVICE_USER]: " input || input=
    SERVICE_USER=${input:-$SERVICE_USER}
    PROXY_BIN="/home/${SERVICE_USER}/.local/bin/claude-code-proxy"
fi
if [[ -t 0 && $# -lt 2 ]]; then
    read -r -p "代理路径 [$PROXY_BIN]: " input || input=
    PROXY_BIN=${input:-$PROXY_BIN}
fi
if [[ -t 0 && $# -lt 3 ]]; then
    printf '出站代理地址选项:\n'
    printf '  1) 固定地址（默认）: %s\n' "$LEGACY_PROXY_URL"
    printf '  2) 自动获取默认网关 IP，端口 8889\n'
    printf '  3) 自定义代理 URL\n'
    read -r -p '请选择 [1]: ' proxy_choice || proxy_choice=
    case ${proxy_choice:-1} in
        1) PROXY_URL=$LEGACY_PROXY_URL ;;
        2) PROXY_URL=auto ;;
        3)
            read -r -p '请输入代理 URL: ' PROXY_URL || PROXY_URL=
            ;;
        *) fail '代理选项无效，请选择 1、2 或 3。' ;;
    esac
fi

[[ $SERVICE_USER =~ ^[a-z_][a-z0-9_-]*$ ]] || fail '服务用户名格式无效。'
[[ $PROXY_BIN =~ ^/[A-Za-z0-9_./+-]+$ ]] || fail '代理路径必须是绝对路径，且不能包含空格或特殊字符。'
[[ $PROXY_URL == auto || $PROXY_URL =~ ^https?://[A-Za-z0-9.-]+:[0-9]{1,5}$ ]] || fail '代理 URL 必须为 auto，或无凭据的 http(s)://主机:端口。'
[[ $NO_PROXY_LIST =~ ^[A-Za-z0-9.,:*/_-]+$ ]] || fail 'CCP_NO_PROXY 包含不支持的字符。'

PASSWD_ENTRY=$(getent passwd "$SERVICE_USER") || fail "系统用户不存在: $SERVICE_USER"
IFS=: read -r _ _ SERVICE_UID _ _ SERVICE_HOME _ <<< "$PASSWD_ENTRY"
[[ $SERVICE_UID =~ ^[0-9]+$ && $SERVICE_UID != 0 ]] || fail '不允许以 root 运行代理服务。'
[[ $SERVICE_HOME =~ ^/[A-Za-z0-9_./+-]+$ && -d $SERVICE_HOME ]] || fail "服务用户的 HOME 无效或不存在: $SERVICE_HOME"
runuser -u "$SERVICE_USER" -- test -x "$SERVICE_HOME" || fail "服务用户无法进入 HOME: $SERVICE_HOME"
runuser -u "$SERVICE_USER" -- test -x "$PROXY_BIN" || fail "服务用户 $SERVICE_USER 无法执行: $PROXY_BIN"
runuser -u "$SERVICE_USER" -- "$PROXY_BIN" --version || fail '代理程序无法在本机运行；Rocky 8 若提示缺少 GLIBC 版本，请先在 Rocky 8 上从源码编译。'
[[ ! -L $UNIT_PATH && ! -L $MANAGED_DROPIN ]] || fail '目标 unit 或托管配置是符号链接，请手动检查。'

if [[ $EXPECTED_OS == rocky ]]; then
    configure_proxy_selinux "$PROXY_BIN"
fi

TMP_UNIT=$(mktemp "${UNIT_PATH}.XXXXXX")
TMP_DROPIN=
cleanup() {
    rm -f "$TMP_UNIT"
    if [[ -n $TMP_DROPIN ]]; then
        rm -f "$TMP_DROPIN"
    fi
}
trap cleanup EXIT
sed \
    -e "s|@SERVICE_USER@|$SERVICE_USER|g" \
    -e "s|@SERVICE_HOME@|$SERVICE_HOME|g" \
    -e "s|@PROXY_BIN@|$PROXY_BIN|g" \
    -e "s|@LAUNCHER_PATH@|$LAUNCHER_PATH|g" \
    -e "s|@PROXY_URL@|$PROXY_URL|g" \
    -e "s|@NO_PROXY_LIST@|$NO_PROXY_LIST|g" \
    "$TEMPLATE_PATH" > "$TMP_UNIT"

if [[ ! -d $DROPIN_DIR ]]; then
    install -d -o root -g root -m 0755 "$DROPIN_DIR"
fi
TMP_DROPIN=$(mktemp "${MANAGED_DROPIN}.XXXXXX")
{
    printf '[Service]\n'
    printf 'User=%s\nWorkingDirectory=%s\nEnvironment=HOME=%s\n' "$SERVICE_USER" "$SERVICE_HOME" "$SERVICE_HOME"
    printf 'Environment="HTTP_PROXY=%s"\nEnvironment="HTTPS_PROXY=%s"\n' "$PROXY_URL" "$PROXY_URL"
    printf 'Environment="NO_PROXY=%s"\n' "$NO_PROXY_LIST"
    printf 'ExecStart=\nExecStart="%s" "%s" "%s"\n' "$LAUNCHER_PATH" "$PROXY_BIN" "$PROXY_URL"
} > "$TMP_DROPIN"

UNIT_BACKUP=
DROPIN_BACKUP=
if [[ -e $UNIT_PATH ]]; then
    UNIT_BACKUP=$(mktemp "${UNIT_PATH}.backup.XXXXXX")
    install -o root -g root -m 0600 "$UNIT_PATH" "$UNIT_BACKUP"
fi
if [[ -e $MANAGED_DROPIN ]]; then
    DROPIN_BACKUP=$(mktemp "${MANAGED_DROPIN}.backup.XXXXXX")
    install -o root -g root -m 0600 "$MANAGED_DROPIN" "$DROPIN_BACKUP"
fi

install -o root -g root -m 0644 "$TMP_UNIT" "$UNIT_PATH"
install -o root -g root -m 0644 "$TMP_DROPIN" "$MANAGED_DROPIN"
install -d -o root -g root -m 0755 "$(dirname -- "$LAUNCHER_PATH")"
install -o root -g root -m 0755 "$LAUNCHER_SOURCE" "$LAUNCHER_PATH"
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
if ! systemctl restart "${SERVICE_NAME}.service"; then
    fail "服务重启失败；旧 unit 备份: ${UNIT_BACKUP:-无}；旧托管配置备份: ${DROPIN_BACKUP:-无}。查看 journalctl -u $SERVICE_NAME -b。"
fi
sleep 1
systemctl is-active --quiet "${SERVICE_NAME}.service" || fail "服务未保持运行；查看 journalctl -u $SERVICE_NAME -b。旧 unit 备份: ${UNIT_BACKUP:-无}。"

printf '已安装/更新并启用 %s.service；出站代理: %s\n' "$SERVICE_NAME" "$PROXY_URL"
[[ -z $UNIT_BACKUP ]] || printf '旧 unit 备份: %s\n' "$UNIT_BACKUP"
[[ -z $DROPIN_BACKUP ]] || printf '旧托管配置备份: %s\n' "$DROPIN_BACKUP"
systemctl --no-pager --full status "${SERVICE_NAME}.service" || true
