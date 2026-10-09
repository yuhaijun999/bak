#!/usr/bin/env bash
set -Eeuo pipefail

EXPECTED_OS=rocky

configure_proxy_selinux() {
    local proxy_bin=$1 proxy_pattern

    command -v selinuxenabled >/dev/null 2>&1 || fail '未找到 selinuxenabled；请先运行 sudo dnf install -y libselinux-utils。'
    selinuxenabled || return 0
    command -v semanage >/dev/null 2>&1 || fail '未找到 semanage；请先运行 sudo dnf install -y policycoreutils-python-utils。'
    command -v restorecon >/dev/null 2>&1 || fail '未找到 restorecon；请先运行 sudo dnf install -y policycoreutils。'

    # 路径已经过 common 脚本校验；转义允许字符中的正则元字符，只匹配此程序。
    proxy_pattern=$(printf '%s' "$proxy_bin" | sed 's/[.+]/\\&/g')
    # Rocky 8 的 semanage -a 会更新已有规则，支持重复安装。
    semanage fcontext -a -t bin_t "$proxy_pattern" || fail "无法设置 SELinux 文件上下文规则: $proxy_bin"
    restorecon -v "$proxy_bin" || fail "无法恢复 SELinux 文件标签: $proxy_bin"
}

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=install-claude-code-proxy-common.sh
source "$SCRIPT_DIR/install-claude-code-proxy-common.sh" "$@"
