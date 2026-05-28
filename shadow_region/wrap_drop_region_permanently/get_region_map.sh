#!/bin/bash

##############################################################################
# 脚本名称: get_region_map.sh
# 功能描述: 获取 DingoDB 集群的 Region Map 信息
# 使用方法: ./get_region_map.sh [输出文件路径]
#          不指定路径时，默认生成当前目录下的 get_region_map.txt
##############################################################################

set -o errexit
set -o nounset

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DINGO_CLI="./dingodb_cli"
readonly DEFAULT_OUTPUT_FILE="get_region_map.txt"

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $SCRIPT_NAME [输出文件路径]

参数:
    输出文件路径    可选，指定完整路径或相对路径
                    不指定时默认为: $DEFAULT_OUTPUT_FILE

示例:
    $SCRIPT_NAME                    # 生成 ./get_region_map.txt
    $SCRIPT_NAME /tmp/region.txt    # 生成 /tmp/region.txt
    $SCRIPT_NAME ../backup/map.txt  # 生成 ../backup/map.txt

EOF
}

# 检查参数
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# 确定输出文件路径
if [[ -n "${1:-}" ]]; then
    OUTPUT_FILE="$1"
else
    OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
fi

# 获取输出文件所在目录（如果路径包含目录）
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ "$OUTPUT_DIR" != "." ]]; then
    # 创建目录（如果不存在）
    mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
        echo "错误: 无法创建目录 $OUTPUT_DIR" >&2
        exit 1
    }
fi

# 检查 dingodb_cli 是否存在
if [[ ! -f "$DINGO_CLI" ]]; then
    echo "错误: 找不到 $DINGO_CLI，请确保在 dingodb_cli 所在目录执行此脚本" >&2
    exit 1
fi

# 检查 dingodb_cli 是否可执行
if [[ ! -x "$DINGO_CLI" ]]; then
    echo "错误: $DINGO_CLI 没有执行权限" >&2
    exit 1
fi

# 执行命令并输出到文件
if $DINGO_CLI GetRegionMap > "$OUTPUT_FILE" 2>&1; then
    echo "Region Map 已保存到: $OUTPUT_FILE"
    
    # 提取并显示统计信息
    if grep -q "region_count=" "$OUTPUT_FILE" 2>/dev/null; then
        STATS_LINE=$(grep "region_count=" "$OUTPUT_FILE" | tail -1)
        echo "$STATS_LINE"
    fi
    
    exit 0
else
    echo "错误: 执行 $DINGO_CLI GetRegionMap 失败" >&2
    exit 1
fi
