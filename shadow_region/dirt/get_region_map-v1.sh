#!/bin/bash

##############################################################################
# 脚本名称: get_region_map.sh
# 功能描述: 获取 DingoDB 集群的 Region Map 信息
# 作者: Auto Generated
# 版本: 1.0
# 创建日期: 2025-01-XX
##############################################################################

set -o errexit      # 命令执行失败时退出
set -o nounset      # 使用未定义变量时退出
set -o pipefail     # 管道命令中任何一个失败都算失败

# 颜色定义（用于日志输出）
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RESET='\033[0m'

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DINGO_CLI="./dingodb_cli"
readonly DEFAULT_FILE_NAME="get_region_map.txt"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=2  # 秒

##############################################################################
# 日志函数
##############################################################################

log_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

##############################################################################
# 帮助信息
##############################################################################

show_usage() {
    cat << EOF
用法: $SCRIPT_NAME [OPTIONS] [OUTPUT_DIR]

获取 DingoDB 集群的 Region Map 信息并保存到文件

参数:
    OUTPUT_DIR              输出目录路径（可选，默认为当前目录）

选项:
    -f, --filename NAME     指定输出文件名（默认: $DEFAULT_FILE_NAME）
    -o, --output PATH       指定完整的输出文件路径（优先级高于 OUTPUT_DIR）
    -q, --quiet             静默模式，不输出日志信息
    --no-color              禁用彩色输出
    --retry NUM             失败时重试次数（默认: $MAX_RETRIES）
    -h, --help              显示此帮助信息

示例:
    $SCRIPT_NAME                            # 保存到 ./get_region_map.txt
    $SCRIPT_NAME /tmp                       # 保存到 /tmp/get_region_map.txt
    $SCRIPT_NAME -f region.txt /var/log     # 保存到 /var/log/region.txt
    $SCRIPT_NAME -o /data/backup/region.txt # 保存到指定完整路径
    $SCRIPT_NAME --quiet /opt/dingodb/data  # 静默模式

退出状态码:
    0  成功
    1  参数错误
    2  执行命令失败
    3  文件写入失败
    4  dingodb_cli 不存在或不可执行

EOF
}

##############################################################################
# 参数解析
##############################################################################

# 初始化变量
output_dir=""
output_file=""
filename="$DEFAULT_FILE_NAME"
quiet_mode=false
retry_count="$MAX_RETRIES"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--filename)
            if [[ -z "${2:-}" ]]; then
                log_error "选项 $1 需要指定文件名"
                exit 1
            fi
            filename="$2"
            shift 2
            ;;
        -o|--output)
            if [[ -z "${2:-}" ]]; then
                log_error "选项 $1 需要指定文件路径"
                exit 1
            fi
            output_file="$2"
            shift 2
            ;;
        -q|--quiet)
            quiet_mode=true
            shift
            ;;
        --no-color)
            unset COLOR_RED COLOR_GREEN COLOR_YELLOW COLOR_RESET
            readonly COLOR_RED=''
            readonly COLOR_GREEN=''
            readonly COLOR_YELLOW=''
            readonly COLOR_RESET=''
            shift
            ;;
        --retry)
            if [[ ! "${2:-}" =~ ^[0-9]+$ ]]; then
                log_error "重试次数必须是数字"
                exit 1
            fi
            retry_count="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            log_error "未知选项: $1"
            show_usage
            exit 1
            ;;
        *)
            # 位置参数作为输出目录
            if [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                log_error "只能指定一个输出目录"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# 如果未指定 output_file，则根据 output_dir 和 filename 构建
if [[ -z "$output_file" ]]; then
    if [[ -z "$output_dir" ]]; then
        output_dir="."
    fi
    output_file="${output_dir}/${filename}"
fi

# 获取输出文件的绝对路径
if [[ "$output_file" != /* ]]; then
    output_file="$(pwd)/$output_file"
fi

# 获取输出目录
output_dir=$(dirname "$output_file")

# 如果非静默模式，输出配置信息
if [[ "$quiet_mode" == false ]]; then
    log_info "脚本启动: $SCRIPT_NAME"
    log_info "输出文件: $output_file"
fi

##############################################################################
# 检查前置条件
##############################################################################

check_prerequisites() {
    # 检查 dingodb_cli 是否存在
    if [[ ! -f "$DINGO_CLI" ]]; then
        log_error "找不到 $DINGO_CLI，请确保脚本在 dingodb_cli 所在目录执行"
        exit 4
    fi
    
    # 检查 dingodb_cli 是否可执行
    if [[ ! -x "$DINGO_CLI" ]]; then
        log_error "$DINGO_CLI 没有执行权限"
        exit 4
    fi
    
    # 检查输出目录是否存在，不存在则创建
    if [[ ! -d "$output_dir" ]]; then
        if [[ "$quiet_mode" == false ]]; then
            log_warn "输出目录不存在，正在创建: $output_dir"
        fi
        mkdir -p "$output_dir" 2>/dev/null || {
            log_error "无法创建输出目录: $output_dir"
            exit 3
        }
    fi
    
    # 检查输出目录是否可写
    if [[ ! -w "$output_dir" ]]; then
        log_error "输出目录不可写: $output_dir"
        exit 3
    fi
    
    # 检查输出文件是否已存在并询问（如果不是静默模式）
    if [[ -f "$output_file" ]] && [[ "$quiet_mode" == false ]]; then
        log_warn "文件已存在: $output_file"
        # 备份现有文件
        backup_file="${output_file}.$(date '+%Y%m%d_%H%M%S').bak"
        if cp "$output_file" "$backup_file" 2>/dev/null; then
            log_info "已备份原文件到: $backup_file"
        else
            log_warn "无法备份原文件，将直接覆盖"
        fi
    fi
}

##############################################################################
# 执行命令获取 Region Map
##############################################################################

get_region_map() {
    local output_file="$1"
    local attempt=1
    local success=false
    
    while [[ $attempt -le $retry_count ]]; do
        if [[ "$quiet_mode" == false ]]; then
            log_info "正在获取 Region Map (尝试 $attempt/$retry_count)..."
        fi
        
        # 执行命令并重定向输出
        if $DINGO_CLI GetRegionMap > "$output_file" 2>&1; then
            success=true
            break
        else
            local exit_code=$?
            if [[ "$quiet_mode" == false ]]; then
                log_warn "命令执行失败 (退出码: $exit_code)"
            fi
            
            if [[ $attempt -lt $retry_count ]]; then
                if [[ "$quiet_mode" == false ]]; then
                    log_info "${RETRY_DELAY}秒后重试..."
                fi
                sleep $RETRY_DELAY
            fi
        fi
        
        ((attempt++))
    done
    
    if [[ "$success" == false ]]; then
        log_error "获取 Region Map 失败，已重试 $retry_count 次"
        return 2
    fi
    
    return 0
}

##############################################################################
# 验证输出文件
##############################################################################

validate_output() {
    local output_file="$1"
    
    # 检查文件是否为空
    if [[ ! -s "$output_file" ]]; then
        log_error "输出文件为空"
        return 3
    fi
    
    # 检查是否包含 region_count（基本的有效性验证）
    if ! grep -q "region_count=" "$output_file" 2>/dev/null; then
        log_warn "输出文件可能不完整，未找到 region_count 信息"
    fi
    
    return 0
}

##############################################################################
# 显示统计信息
##############################################################################

show_statistics() {
    local output_file="$1"
    
    if [[ "$quiet_mode" == true ]]; then
        return
    fi
    
    # 提取统计信息
    if grep -q "region_count=" "$output_file" 2>/dev/null; then
        local stats=$(grep "region_count=" "$output_file" | tail -1)
        log_info "统计信息: $stats"
    fi
    
    # 统计各种状态的数量
    local total_count=$(grep -c "^id=" "$output_file" 2>/dev/null || echo "0")
    local degraded_count=$(grep -c "REPLICA_DEGRAED" "$output_file" 2>/dev/null || echo "0")
    local normal_count=$(grep -c "REPLICA_NORMAL" "$output_file" 2>/dev/null || echo "0")
    local none_count=$(grep -c "REPLICA_NONE" "$output_file" 2>/dev/null || echo "0")
    
    log_info "Region 统计: 总计=$total_count, 正常=$normal_count, 降级=$degraded_count, 无副本=$none_count"
    
    # 如果有降级的 region，输出警告
    if [[ $degraded_count -gt 0 ]]; then
        log_warn "发现 $degraded_count 个 REPLICA_DEGRAED 状态的 region"
        if [[ "$quiet_mode" == false ]]; then
            echo ""
            echo "=== REPLICA_DEGRAED Regions ==="
            grep "REPLICA_DEGRAED" "$output_file" | grep -oP 'id=\K\d+' | while read rid; do
                echo "  - Region ID: $rid"
            done
        fi
    fi
    
    # 获取文件大小
    local file_size=$(ls -lh "$output_file" | awk '{print $5}')
    log_info "文件大小: $file_size"
}

##############################################################################
# 主函数
##############################################################################

main() {
    # 检查前置条件
    check_prerequisites || exit $?
    
    # 获取 Region Map
    get_region_map "$output_file" || exit $?
    
    # 验证输出
    validate_output "$output_file" || exit $?
    
    # 显示统计信息
    show_statistics "$output_file"
    
    if [[ "$quiet_mode" == false ]]; then
        log_info "Region Map 已成功保存到: $output_file"
    fi
    
    exit 0
}

# 执行主函数
main "$@"

