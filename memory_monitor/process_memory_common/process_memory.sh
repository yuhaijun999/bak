#!/usr/bin/env bash

# 持续监控进程物理内存，并在总 PSS 占用高于最近一次保存值时保存 Top N 快照。
# 可通过环境变量配置：
#   INTERVAL_SECONDS=5 TOP_N=10 OUTPUT_FILE=/tmp/process_memory.log ./process_memory.sh

set -u

LC_ALL=C
export LC_ALL

INTERVAL_SECONDS=${INTERVAL_SECONDS:-5}
TOP_N=${TOP_N:-10}
OUTPUT_FILE=${OUTPUT_FILE:-./process_memory.log}
HOST_NAME=$(hostname 2>/dev/null || printf '[unknown]')
START_ARGS="$*"

human_memory() {
    local kb=$1
    awk -v kb="$kb" 'BEGIN {
        if (kb >= 1048576)
            printf "%.2f GiB", kb / 1048576
        else if (kb >= 1024)
            printf "%.2f MiB", kb / 1024
        else
            printf "%d KiB", kb
    }'
}

usage() {
    cat <<'EOF'
用法：
  process_memory.sh [-i 秒] [-n 进程数] [-o 输出文件]

也可以使用环境变量：
  INTERVAL_SECONDS=5 TOP_N=10 OUTPUT_FILE=./process_memory.log ./process_memory.sh
EOF
}

while getopts ':i:n:o:h' opt; do
    case "$opt" in
        i) INTERVAL_SECONDS=$OPTARG ;;
        n) TOP_N=$OPTARG ;;
        o) OUTPUT_FILE=$OPTARG ;;
        h) usage; exit 0 ;;
        :) echo "选项 -$OPTARG 需要参数" >&2; usage >&2; exit 2 ;;
        \?) echo "未知选项: -$OPTARG" >&2; usage >&2; exit 2 ;;
    esac
done

if ! [[ "$INTERVAL_SECONDS" =~ ^[1-9][0-9]*([.][0-9]+)?$ ]]; then
    echo "间隔必须是大于 0 的数字: $INTERVAL_SECONDS" >&2
    exit 2
fi
if ! [[ "$TOP_N" =~ ^[1-9][0-9]*$ ]]; then
    echo "进程数必须是正整数: $TOP_N" >&2
    exit 2
fi

output_dir=${OUTPUT_FILE%/*}
[[ "$output_dir" == "$OUTPUT_FILE" ]] && output_dir='.'
if [[ ! -d "$output_dir" ]]; then
    echo "输出目录不存在: $output_dir" >&2
    exit 2
fi

tmp_file=$(mktemp)
trap 'rm -f "$tmp_file" "${OUTPUT_FILE}.tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# [本次修改] 保存本次脚本运行期间最近一次写入文件的最大总内存值。
saved_total_kb=-1
first_snapshot=true
sample_count=0
update_count=0

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')
    : > "$tmp_file"
    total_kb=0

    for proc_dir in /proc/[0-9]*; do
        [[ -d "$proc_dir" ]] || continue

        pid=${proc_dir##*/}
        rollup_file="$proc_dir/smaps_rollup"

        if [[ -r "$rollup_file" ]]; then
            memory_kb=$(awk '/^Pss:/ {print $2; exit}' "$rollup_file" 2>/dev/null || true)
            method='PSS'
        else
            memory_kb=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1}')
            method='RSS(回退)'
        fi
        [[ "$memory_kb" =~ ^[0-9]+$ ]] || continue

        name=$(readlink "$proc_dir/exe" 2>/dev/null || true)
        if [[ -z "$name" ]]; then
            name=$(ps -o comm= -p "$pid" 2>/dev/null | sed -n '1p')
        fi
        [[ -n "$name" ]] || name='[unknown]'

        total_kb=$((total_kb + memory_kb))
        printf '%s\t%s\t%s\t%s\n' "$pid" "$name" "$memory_kb" "$method" >> "$tmp_file"
    done

    sample_count=$((sample_count + 1))

    # [本次修改] 首次成功统计无条件覆盖已有文件；之后仅在总内存超过
    # 最近一次保存值（即本次启动以来的最大值）时覆盖。
    if [[ "$first_snapshot" == true ]] || (( total_kb > saved_total_kb )); then
        update_count=$((update_count + 1))
        total_human=$(human_memory "$total_kb")
        {
            printf '主机名: %s\n' "$HOST_NAME"
            printf '统计时间: %s\n' "$timestamp"
            printf '统计次数: %s\n' "$sample_count"
            printf '更新次数: %s\n' "$update_count"
            printf '执行间隔: %s 秒\n' "$INTERVAL_SECONDS"
            printf '显示进程数: %s\n' "$TOP_N"
            printf '输出文件: %s\n' "$OUTPUT_FILE"
            printf '启动参数: %s\n' "$START_ARGS"
            printf '所有进程总内存: %s (%s KiB)\n' "$total_human" "$total_kb"
            printf '%-10s %-80s %14s %s\n' 'PID' '进程完整路径' '物理内存' '统计方式'
            printf '%-10s %-80s %14s %s\n' '----------' '--------------------------------------------------------------------------------' '--------------' '--------'
            sort -t $'\t' -k3,3nr "$tmp_file" | head -n "$TOP_N" | awk -F '\t' '
            {
                kb = $3
                if (kb >= 1048576)
                    mem = sprintf("%.2f GiB", kb / 1048576)
                else if (kb >= 1024)
                    mem = sprintf("%.2f MiB", kb / 1024)
                else
                    mem = sprintf("%d KiB", kb)
                printf "%-10s %-80s %14s %s\n", $1, $2, mem, $4
            }'
        } > "${OUTPUT_FILE}.tmp"
        mv -f "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        echo "[$timestamp] 统计次数 $sample_count，更新次数 $update_count，总内存 ${total_kb} KiB，已更新 $OUTPUT_FILE"
        first_snapshot=false
        # [本次修改] 仅在日志实际写入成功后更新比较基准。
        saved_total_kb=$total_kb
    else
        # [本次修改] 当前值未超过本次启动以来的最大已保存值，不覆盖文件。
        echo "[$timestamp] 统计次数 $sample_count，更新次数 $update_count，总内存 ${total_kb} KiB，未超过文件中已保存值 ${saved_total_kb} KiB"
    fi

    sleep "$INTERVAL_SECONDS"
done
