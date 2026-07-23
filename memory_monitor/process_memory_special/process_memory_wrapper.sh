#!/usr/bin/env bash

set -u

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
host_name=$(hostname 2>/dev/null || printf 'unknown')

# 防止主机名中的特殊字符影响日志文件名。
host_name=$(printf '%s' "$host_name" | sed 's/[^A-Za-z0-9._-]/_/g')
output_file="./${host_name}_process_memory.log"

exec "$script_dir/process_memory.sh" \
    -i 60 \
    -n 20 \
    -o "$output_file"
