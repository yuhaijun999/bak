#!/usr/bin/env bash
# 适用于 Ubuntu 24.04 和 Rocky Linux 8；将所有参数传递给 claude。
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
    printf '错误: 未找到 claude，请先安装 Claude Code 并确保其位于 PATH 中。\n' >&2
    exit 127
fi

# 本地 Claude Code Proxy 请求必须直连；兼容大小写代理环境变量。
local_no_proxy="localhost,127.0.0.1,server.teleport.zetyun.cn,::1"
export NO_PROXY="${NO_PROXY:+${NO_PROXY},}${no_proxy:+${no_proxy},}${local_no_proxy}"
export no_proxy="$NO_PROXY"

export ANTHROPIC_BASE_URL='http://127.0.0.1:18765'
export ANTHROPIC_AUTH_TOKEN='unused'
export ANTHROPIC_MODEL='gpt-6-sol[1m]'
export ANTHROPIC_SMALL_FAST_MODEL='gpt-6-luna[1m]'
export CLAUDE_CODE_AUTO_COMPACT_WINDOW='272000'
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'
export CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK='1'

exec claude "$@"
