#!/bin/bash

##############################################################################
# 脚本名称: format_degraded_region.sh
# 功能描述: 从降级 Region 文件中提取关键信息（id, name, state, leader）
# 使用方法: ./format_degraded_region.sh [输入文件] [输出文件]
#          输入文件默认: ./find_degraded_region_from_map.txt
#          输出文件默认: ./format_degraded_region.txt
##############################################################################

readonly DEFAULT_INPUT_FILE="./find_degraded_region_from_map.txt"
readonly DEFAULT_OUTPUT_FILE="./format_degraded_region.txt"

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $0 [输入文件] [输出文件]

从降级 Region 文件中提取关键信息（id, name, state, leader）

参数:
    输入文件    包含降级 Region 信息的文件路径（默认: $DEFAULT_INPUT_FILE）
    输出文件    保存提取结果的文件路径（默认: $DEFAULT_OUTPUT_FILE）

示例:
    $0                                          # 使用默认文件
    $0 degraded.txt                             # 指定输入文件
    $0 degraded.txt result.txt                  # 指定输入和输出文件
    $0 -h                                       # 显示帮助信息

输出格式:
    id=xxx name=xxx state=REPLICA_DEGRAED leader=xxx

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
    /^id=/ {
        # 提取 id
        match($0, /id=[0-9]+/)
        id = substr($0, RSTART+3, RLENGTH-3)
        
        # 提取 name
        match($0, /name=[^ ]+/)
        name = substr($0, RSTART+5, RLENGTH-5)
        
        # 提取 leader
        match($0, /leader=[0-9]+/)
        if (RSTART > 0) {
            leader = substr($0, RSTART+7, RLENGTH-7)
        } else {
            leader = "0"
        }
        
        # 输出格式化结果
        printf "id=%s name=%s state=REPLICA_DEGRAED leader=%s\n", id, name, leader
    }
' "$INPUT_FILE" > "$OUTPUT_FILE"

# 统计结果
COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ')

# 输出结果信息
echo "========================================="
echo "处理完成"
echo "输入文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"
echo "处理 Region 数量: $COUNT"
echo "========================================="

if [[ $COUNT -gt 0 ]]; then
    echo ""
    echo "输出内容:"
    cat "$OUTPUT_FILE"
    echo "========================================="
fi

exit 0
