#!/bin/bash

##############################################################################
# 脚本名称: format_store_map_file.sh
# 功能描述: 从 Store Map 输出中提取关键信息（ID, Type, Address）
# 使用方法: ./format_store_map_file.sh [输入文件] [输出文件]
#          输入文件默认: ./get_store_map.txt
#          输出文件默认: ./format_store_map_file.txt
##############################################################################

set -o errexit
set -o nounset
set -o pipefail

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DEFAULT_INPUT_FILE="./get_store_map.txt"
readonly DEFAULT_OUTPUT_FILE="./format_store_map_file.txt"

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $SCRIPT_NAME [输入文件] [输出文件]

从 Store Map 输出中提取关键信息（ID, Type, Address）

参数:
    输入文件    包含 Store Map 输出的文件路径（默认: $DEFAULT_INPUT_FILE）
    输出文件    保存提取结果的文件路径（默认: $DEFAULT_OUTPUT_FILE）

示例:
    $SCRIPT_NAME                                    # 使用默认文件
    $SCRIPT_NAME store.txt                          # 指定输入文件
    $SCRIPT_NAME store.txt result.txt               # 指定输入和输出文件
    $SCRIPT_NAME -h                                 # 显示帮助信息

输出格式:
    ID Type Address
    31001 NODE_TYPE_INDEX 172.30.14.11:31001

EOF
}

# 检查帮助
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# 获取参数
INPUT_FILE="${1:-$DEFAULT_INPUT_FILE}"
OUTPUT_FILE="${2:-$DEFAULT_OUTPUT_FILE}"

# 检查输入文件
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "错误: 输入文件不存在: $INPUT_FILE" >&2
    exit 1
fi

# 创建输出目录
mkdir -p "$(dirname "$OUTPUT_FILE")" 2>/dev/null

# 使用 awk 处理提取信息
awk '
    # 匹配表格中的数据行（以 | 开头和结尾）
    /^\|/ && !/ID\|/ && !/===/ && !/Summary/ && !/DINGODB/ {
        # 移除首尾的空格和竖线
        gsub(/^[[:space:]]*\|[[:space:]]*/, "", $0)
        gsub(/[[:space:]]*\|[[:space:]]*$/, "", $0)
        
        # 按竖线分割字段
        split($0, fields, /[[:space:]]*\|[[:space:]]*/)
        
        # 提取需要的字段
        if (length(fields) >= 7) {
            id = fields[1]
            type = fields[2]
            address = fields[3]
            
            # 去掉 Address 字段最后的 :0
            gsub(/:0$/, "", address)
            
            # 输出格式化结果
            printf "%-8s %-20s %s\n", id, type, address
        }
    }
' "$INPUT_FILE" > "$OUTPUT_FILE"

# 统计结果
COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ')

# 输出结果信息
echo "========================================="
echo "处理完成"
echo "输入文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"
echo "处理 Store 数量: $COUNT"
echo "========================================="

if [[ $COUNT -gt 0 ]]; then
    echo ""
    echo "输出内容:"
    echo "----------------------------------------"
    cat "$OUTPUT_FILE"
    echo "----------------------------------------"
else
    echo "警告: 未提取到任何 Store 信息" >&2
    exit 2
fi

echo "========================================="

exit 0

