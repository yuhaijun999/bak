#!/usr/bin/env bash
set -euo pipefail

proxy_bin=${1:?代理可执行文件路径缺失}
proxy_url=${2:?代理 URL 缺失}

if [[ $proxy_url == auto ]]; then
    gateway=$(ip route show | grep -i default | awk '{ print $3 }' | head -n 1)
    [[ $gateway =~ ^[0-9]+(\.[0-9]+){3}$ ]] || {
        printf '错误: 无法从默认路由获取有效网关 IP。\n' >&2
        exit 1
    }
    proxy_url="http://${gateway}:8889"
fi

export HTTP_PROXY=$proxy_url
export HTTPS_PROXY=$proxy_url
exec "$proxy_bin" serve --no-monitor
