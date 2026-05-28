#!/bin/bash

##############################################################################
# 脚本名称: drop_region_permanently.sh
# 功能描述: 批量永久删除 Shadow Region
# 使用方法: ./drop_region_permanently.sh [输入文件] [输出文件] [--dry-run] [--debug]
#          输入文件默认: ./find_shadow_region.txt
#          输出文件默认: ./drop_region_permanently.txt
##############################################################################

set -o nounset
set -o pipefail

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DEFAULT_INPUT_FILE="./find_shadow_region.txt"
readonly DEFAULT_OUTPUT_FILE="./drop_region_permanently.txt"
readonly DINGO_CLI="./dingodb_cli"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# 全局变量
DEBUG_MODE=false
DRY_RUN=false

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
使用方法: $SCRIPT_NAME [输入文件] [输出文件] [--dry-run] [--debug]

批量永久删除 Shadow Region

参数:
    输入文件    包含 Shadow Region 信息的文件路径（默认: $DEFAULT_INPUT_FILE）
    输出文件    保存删除结果的文件路径（默认: $DEFAULT_OUTPUT_FILE）
    --dry-run   试运行模式，只显示将要执行的操作，不实际删除
    --debug     启用调试模式，显示详细执行信息

示例:
    $SCRIPT_NAME                                    # 使用默认文件
    $SCRIPT_NAME shadow.txt                         # 指定输入文件
    $SCRIPT_NAME shadow.txt result.txt              # 指定输入和输出文件
    $SCRIPT_NAME --dry-run                          # 试运行模式
    $SCRIPT_NAME --debug                            # 调试模式

输出文件格式:
    id name result

退出状态码:
    0  全部成功
    1  参数错误
    2  输入文件不存在或无法读取
    3  部分失败或全部失败

EOF
}

# 解析参数
parse_args() {
    DEBUG_MODE=false
    DRY_RUN=false
    INPUT_FILE=""
    OUTPUT_FILE=""
    
    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            DEBUG_MODE=true
        fi
        if [[ "$arg" == "--dry-run" ]]; then
            DRY_RUN=true
        fi
    done
    
    local args=()
    for arg in "$@"; do
        if [[ "$arg" != "--debug" ]] && [[ "$arg" != "--dry-run" ]]; then
            args+=("$arg")
        fi
    done
    
    INPUT_FILE="${args[0]:-}"
    OUTPUT_FILE="${args[1]:-}"
    
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
    
    if [[ ! -x "$DINGO_CLI" ]]; then
        log_error "$DINGO_CLI 没有执行权限或不存在"
        exit 1
    fi
}

# 从行中提取 id
extract_id() {
    local line="$1"
    echo "$line" | sed -n 's/^id=\([0-9]*\).*/\1/p'
}

# 从行中提取 name
extract_name() {
    local line="$1"
    echo "$line" | sed -n 's/.*name=\([^ ]*\).*/\1/p'
}

# 执行删除单个 Region
drop_region() {
    local region_id="$1"
    local region_name="$2"
    
    local cmd="$DINGO_CLI DropRegionPermanently --id=$region_id"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] 将会执行: $cmd"
        echo "DRY-RUN"
        return 0
    fi
    
    log_debug "执行命令: $cmd"
    
    local output
    local exit_code
    
    set +e
    output=$($cmd 2>&1)
    exit_code=$?
    set -e
    
    log_debug "命令退出码: $exit_code"
    log_debug "输出: $output"
    
    if [[ $exit_code -eq 0 ]]; then
        if echo "$output" | grep -qi "success\|ok\|dropped"; then
            echo "SUCCESS"
            return 0
        elif echo "$output" | grep -q "not exist"; then
            log_warn "Region $region_id ($region_name) 不存在"
            echo "NOT_EXIST"
            return 0
        else
            log_warn "Region $region_id ($region_name) 执行结果未知"
            echo "UNKNOWN"
            return 0
        fi
    else
        log_error "删除 Region $region_id ($region_name) 失败，退出码: $exit_code"
        echo "FAILED"
        return 1
    fi
}

# 批量删除 Shadow Region
batch_drop_regions() {
    local input_file="$1"
    local output_file="$2"
    
    > "$output_file"
    
    local total_count=0
    local success_count=0
    local failed_count=0
    local not_exist_count=0
    
    # 写入表头
    echo "# id name result" >> "$output_file"
    echo "# 执行时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$output_file"
    if [[ "$DRY_RUN" == true ]]; then
        echo "# 模式: DRY-RUN (试运行，未实际删除)" >> "$output_file"
    fi
    echo "# ========================================" >> "$output_file"
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local region_id=$(extract_id "$line")
        local region_name=$(extract_name "$line")
        
        if [[ -z "$region_id" ]]; then
            log_warn "无法提取 ID，跳过行: $line"
            continue
        fi
        
        if [[ -z "$region_name" ]]; then
            region_name="unknown"
        fi
        
        ((total_count++))
        
        echo ""
        echo "----------------------------------------"
        log_info "[$total_count] 处理 Region: $region_id ($region_name)"
        
        local result
        result=$(drop_region "$region_id" "$region_name")
        
        echo "$region_id $region_name $result" >> "$output_file"
        
        case "$result" in
            SUCCESS)
                ((success_count++))
                log_info "  ✅ 删除成功"
                ;;
            NOT_EXIST)
                ((not_exist_count++))
                log_warn "  ⚠️ Region 不存在"
                ;;
            FAILED)
                ((failed_count++))
                log_error "  ❌ 删除失败"
                ;;
            UNKNOWN)
                ((success_count++))
                log_warn "  ⚠️ 结果未知，但命令执行成功"
                ;;
            DRY-RUN)
                ((success_count++))
                log_info "  🔍 [DRY-RUN] 将执行删除"
                ;;
        esac
    done < "$input_file"
    
    # 返回统计信息
    echo "$total_count $success_count $failed_count $not_exist_count"
}

# 显示汇总结果
show_summary() {
    local output_file="$1"
    local total_count="$2"
    local success_count="$3"
    local failed_count="$4"
    local not_exist_count="$5"
    
    echo ""
    echo "========================================="
    echo "执行完成"
    echo "========================================="
    echo "输入文件: $INPUT_FILE"
    echo "输出文件: $OUTPUT_FILE"
    if [[ "$DRY_RUN" == true ]]; then
        echo "模式: DRY-RUN (试运行)"
    fi
    echo "========================================="
    echo "统计信息:"
    echo "  总数: $total_count"
    echo "  成功: $success_count"
    echo "  失败: $failed_count"
    echo "  不存在: $not_exist_count"
    echo "========================================="
    
    if [[ $failed_count -gt 0 ]]; then
        echo ""
        log_error "失败的 Region:"
        while IFS= read -r line; do
            if [[ "$line" =~ FAILED$ ]]; then
                local id=$(echo "$line" | awk '{print $1}')
                local name=$(echo "$line" | awk '{print $2}')
                echo "  - ID: $id, Name: $name"
            fi
        done < "$output_file"
        echo "========================================="
    fi
}

# 主函数
main() {
    parse_args "$@"
    
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "[DEBUG] 调试模式已启用" >&2
        echo "[DEBUG] 参数: INPUT_FILE=$INPUT_FILE, OUTPUT_FILE=$OUTPUT_FILE, DRY_RUN=$DRY_RUN" >&2
    fi
    
    validate_args
    
    echo ""
    echo "========================================="
    log_info "开始批量删除 Shadow Region"
    echo "========================================="
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "试运行模式: 只显示将要执行的操作，不会实际删除"
    fi
    echo "========================================="
    
    local stats
    stats=$(batch_drop_regions "$INPUT_FILE" "$OUTPUT_FILE")
    
    # 使用 read 解析统计信息
    read -r total_count success_count failed_count not_exist_count <<< "$stats"
    
    show_summary "$OUTPUT_FILE" "$total_count" "$success_count" "$failed_count" "$not_exist_count"
    
    if [[ $failed_count -gt 0 ]]; then
        exit 3
    fi
    
    exit 0
}

main "$@"
