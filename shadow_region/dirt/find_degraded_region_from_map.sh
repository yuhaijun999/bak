#!/bin/bash

##############################################################################
# 脚本名称: find_degraded_region_from_map.sh
# 功能描述: 从 Region Map 输出中查找 REPLICA_DEGRAED 状态的 Region
# 使用方法: ./find_degraded_region_from_map.sh [输入文件] [输出文件]
#          输入文件默认: ./get_region_map.txt
#          输出文件默认: ./find_degraded_region_from_map.txt
##############################################################################

set -o errexit
set -o nounset
set -o pipefail

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DEFAULT_INPUT_FILE="./get_region_map.txt"
readonly DEFAULT_OUTPUT_FILE="./find_degraded_region_from_map.txt"
readonly DEGRADED_STATUS="REPLICA_DEGRAED"

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $SCRIPT_NAME [输入文件] [输出文件]

从 Region Map 输出中查找 REPLICA_DEGRAED 状态的 Region 并输出到文件

参数:
    输入文件    包含 Region Map 输出的文件路径（默认: $DEFAULT_INPUT_FILE）
    输出文件    保存降级 Region 信息的文件路径（默认: $DEFAULT_OUTPUT_FILE）

示例:
    $SCRIPT_NAME                                    # 使用默认文件
    $SCRIPT_NAME region.txt                         # 指定输入文件，输出使用默认
    $SCRIPT_NAME region.txt degraded.txt            # 指定输入和输出文件
    $SCRIPT_NAME -h                                 # 显示帮助信息

退出状态码:
    0  成功（发现或未发现降级 Region 都算成功）
    1  参数错误或文件读取失败

EOF
}

# 检查参数
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# 获取输入文件（第1个参数）
if [[ -n "${1:-}" ]]; then
    INPUT_FILE="$1"
else
    INPUT_FILE="$DEFAULT_INPUT_FILE"
fi

# 获取输出文件（第2个参数）
if [[ -n "${2:-}" ]]; then
    OUTPUT_FILE="$2"
else
    OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
fi

# 检查输入文件是否存在
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "错误: 输入文件不存在: $INPUT_FILE" >&2
    exit 1
fi

# 检查输入文件是否可读
if [[ ! -r "$INPUT_FILE" ]]; then
    echo "错误: 输入文件不可读: $INPUT_FILE" >&2
    exit 1
fi

# 获取输出文件所在目录
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ "$OUTPUT_DIR" != "." ]] && [[ "$OUTPUT_DIR" != "/" ]]; then
    # 创建输出目录（如果不存在）
    mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
        echo "错误: 无法创建输出目录: $OUTPUT_DIR" >&2
        exit 1
    }
fi

# 查找降级 Region 并输出到文件（确保只匹配以 id= 开头的行）
grep "^id=.*$DEGRADED_STATUS" "$INPUT_FILE" > "$OUTPUT_FILE" 2>/dev/null || true

# 统计找到的行数
if [[ -f "$OUTPUT_FILE" ]]; then
    DEGRADED_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null | tr -d ' ')
else
    DEGRADED_COUNT=0
fi

# 输出结果信息
echo "========================================="
echo "查找完成"
echo "输入文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"
echo "降级 Region 数量: $DEGRADED_COUNT"
echo "========================================="

# 显示统计信息（从输入文件中提取）
if grep -q "region_count=" "$INPUT_FILE" 2>/dev/null; then
    STATS_LINE=$(grep "region_count=" "$INPUT_FILE" | tail -1)
    echo "集群统计: $STATS_LINE"
    echo "========================================="
fi

# 如果有降级 Region，显示简要信息
if [[ $DEGRADED_COUNT -gt 0 ]]; then
    echo ""
    echo "降级 Region ID 列表:"
    # 修复：更精确地提取 Region ID
    grep -oP '^id=\K\d+' "$OUTPUT_FILE" | while read -r rid; do
        if [[ -n "$rid" ]]; then
            echo "  - Region ID: $rid"
        fi
    done
    echo "========================================="
else
    echo ""
    echo "✅ 未发现 REPLICA_DEGRAED 状态的 Region"
    echo "========================================="
fi

exit 0

