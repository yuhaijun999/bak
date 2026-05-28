#!/bin/bash

##############################################################################
# 脚本名称: find_shadow_region.sh
# 功能描述: 从 Region Map 输出中查找 Shadow Region
#           Shadow Region 特征: state包含REGION_NEW且leader=0且REPLICA_NONE
# 使用方法: ./find_shadow_region.sh [输入文件] [输出文件]
#          输入文件默认: ./get_region_map.txt
#          输出文件默认: ./find_shadow_region.txt
##############################################################################

set -o nounset
set -o pipefail

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DEFAULT_INPUT_FILE="./get_region_map.txt"
readonly DEFAULT_OUTPUT_FILE="./find_shadow_region.txt"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# 全局变量
DEBUG_MODE=false

# 日志函数
log_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*" >&2
    fi
}

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $SCRIPT_NAME [输入文件] [输出文件] [--debug]

从 Region Map 输出中查找 Shadow Region

Shadow Region 特征:
    - state 包含 REGION_NEW
    - state 包含 REPLICA_NONE  
    - leader = 0

参数:
    输入文件    包含 Region Map 输出的文件路径（默认: $DEFAULT_INPUT_FILE）
    输出文件    保存 Shadow Region 信息的文件路径（默认: $DEFAULT_OUTPUT_FILE）
    --debug     启用调试模式，显示详细执行信息

示例:
    $SCRIPT_NAME                                    # 使用默认文件
    $SCRIPT_NAME region.txt                         # 指定输入文件
    $SCRIPT_NAME region.txt shadow.txt              # 指定输入和输出文件
    $SCRIPT_NAME --debug                            # 调试模式

输出格式:
    保持原始格式，只输出符合条件的行

退出状态码:
    0  成功
    1  参数错误
    2  输入文件不存在或无法读取
    3  未找到 Shadow Region

EOF
}

# 解析参数
parse_args() {
    DEBUG_MODE=false
    INPUT_FILE=""
    OUTPUT_FILE=""
    
    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            DEBUG_MODE=true
        fi
    done
    
    local args=()
    for arg in "$@"; do
        if [[ "$arg" != "--debug" ]]; then
            args+=("$arg")
        fi
    done
    
    INPUT_FILE="${args[0]:-}"
    OUTPUT_FILE="${args[1]:-}"
    
    # 设置默认值
    INPUT_FILE="${INPUT_FILE:-$DEFAULT_INPUT_FILE}"
    OUTPUT_FILE="${OUTPUT_FILE:-$DEFAULT_OUTPUT_FILE}"
}

# 验证参数
validate_args() {
    if [[ "$INPUT_FILE" == "-h" ]] || [[ "$INPUT_FILE" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ ! -f "$INPUT_FILE" ]]; then
        log_error "输入文件不存在: $INPUT_FILE"
        exit 2
    fi
    
    if [[ ! -r "$INPUT_FILE" ]]; then
        log_error "输入文件不可读: $INPUT_FILE"
        exit 2
    fi
}

# 查找 Shadow Region
find_shadow_regions() {
    local input_file="$1"
    local output_file="$2"
    
    log_debug "开始查找 Shadow Region..."
    log_debug "输入文件: $input_file"
    log_debug "输出文件: $output_file"
    log_debug "查找条件: state包含 REGION_NEW 且 state包含 REPLICA_NONE 且 leader=0"
    
    # 清空输出文件
    > "$output_file"
    
    local count=0
    
    # 逐行读取并匹配 Shadow Region
    while IFS= read -r line; do
        # 跳过空行
        if [[ -z "$line" ]]; then
            continue
        fi
        
        # 检查条件:
        # 1. 以 "id=" 开头
        # 2. 包含 "REGION_NEW"
        # 3. 包含 "REPLICA_NONE"
        # 4. 包含 "leader=0"
        if echo "$line" | grep -q "^id=" && \
           echo "$line" | grep -q "REGION_NEW" && \
           echo "$line" | grep -q "REPLICA_NONE" && \
           echo "$line" | grep -q "leader=0"; then
            
            # 输出匹配的行
            echo "$line" >> "$output_file"
            ((count++))
            log_debug "找到 Shadow Region: $(echo "$line" | grep -oP 'id=\K\d+')"
        fi
    done < "$input_file"
    
    echo "$count"
}

# 提取并显示统计信息
show_statistics() {
    local input_file="$1"
    local output_file="$2"
    local shadow_count="$3"
    
    echo ""
    echo "========================================="
    echo "查找完成"
    echo "========================================="
    echo "输入文件: $input_file"
    echo "输出文件: $output_file"
    echo "Shadow Region 数量: $shadow_count"
    echo "========================================="
    
    # 显示原始统计信息
    if grep -q "region_count=" "$input_file" 2>/dev/null; then
        local stats_line=$(grep "region_count=" "$input_file" | tail -1)
        echo "集群统计: $stats_line"
        echo "========================================="
    fi
    
    # 如果有 Shadow Region，显示简要信息
    if [[ $shadow_count -gt 0 ]]; then
        echo ""
        echo "Shadow Region ID 列表:"
        grep -oP 'id=\K\d+' "$output_file" | while read -r rid; do
            echo "  - Region ID: $rid"
        done
        echo "========================================="
    else
        echo ""
        log_info "✅ 未发现 Shadow Region"
        echo "========================================="
    fi
}

# 显示输出文件内容（可选，调试用）
show_output_content() {
    local output_file="$1"
    local shadow_count="$2"
    
    if [[ $shadow_count -gt 0 ]] && [[ "$DEBUG_MODE" == true ]]; then
        echo ""
        echo "========================================="
        echo "Shadow Region 详细内容:"
        echo "========================================="
        cat "$output_file"
        echo "========================================="
    fi
}

# 主函数
main() {
    parse_args "$@"
    
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "[DEBUG] 调试模式已启用" >&2
        echo "[DEBUG] 参数: INPUT_FILE=$INPUT_FILE, OUTPUT_FILE=$OUTPUT_FILE" >&2
    fi
    
    validate_args
    
    echo ""
    echo "========================================="
    log_info "开始查找 Shadow Region"
    echo "========================================="
    log_info "查找条件:"
    log_info "  - state 包含 REGION_NEW"
    log_info "  - state 包含 REPLICA_NONE"
    log_info "  - leader = 0"
    echo "========================================="
    
    # 查找 Shadow Region
    local shadow_count
    shadow_count=$(find_shadow_regions "$INPUT_FILE" "$OUTPUT_FILE")
    
    # 显示统计信息
    show_statistics "$INPUT_FILE" "$OUTPUT_FILE" "$shadow_count"
    
    # 调试模式下显示详细内容
    show_output_content "$OUTPUT_FILE" "$shadow_count"
    
    # 返回退出码
    if [[ $shadow_count -eq 0 ]]; then
        exit 3
    fi
    
    exit 0
}

# 执行主函数
main "$@"

