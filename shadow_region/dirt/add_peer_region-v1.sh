
#!/bin/bash

##############################################################################
# 脚本名称: add_peer_region.sh
# 功能描述: 向指定 Store 添加 Peer Region
# 使用方法: ./add_peer_region.sh <region_id> <store_id>
#          region_id: Region ID（必须为大于0的整数）
#          store_id: Store ID（必须为大于0的整数）
##############################################################################

set -o nounset
set -o pipefail

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DINGO_CLI="./dingodb_cli"
readonly DEFAULT_STORE_MAP="./format_store_map_file.txt"

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
使用方法: $SCRIPT_NAME <region_id> <store_id> [--debug]

向指定 Store 添加 Peer Region

参数:
    region_id       Region ID（必须为大于0的整数）
    store_id        Store ID（必须为大于0的整数）
    --debug         启用调试模式，显示详细执行信息

示例:
    $SCRIPT_NAME 80013 30003
    $SCRIPT_NAME 80013 30003 --debug

注意:
    添加 Peer Region 后，系统会自动验证 Peer 是否成功添加

退出状态码:
    0  成功
    1  参数错误
    2  执行命令失败
    3  Store ID 不在 Store Map 中

EOF
}

# 解析参数
parse_args() {
    DEBUG_MODE=false
    REGION_ID=""
    STORE_ID=""
    
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
    
    REGION_ID="${args[0]:-}"
    STORE_ID="${args[1]:-}"
}

# 验证参数
validate_args() {
    if [[ "$REGION_ID" == "-h" ]] || [[ "$REGION_ID" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    if [[ -z "$REGION_ID" ]] || [[ -z "$STORE_ID" ]]; then
        log_error "必须提供 region_id 和 store_id"
        show_usage
        exit 1
    fi
    
    if ! [[ "$REGION_ID" =~ ^[0-9]+$ ]] || [[ "$REGION_ID" -le 0 ]]; then
        log_error "region_id 必须是大于0的整数，当前值: $REGION_ID"
        exit 1
    fi
    
    if ! [[ "$STORE_ID" =~ ^[0-9]+$ ]] || [[ "$STORE_ID" -le 0 ]]; then
        log_error "store_id 必须是大于0的整数，当前值: $STORE_ID"
        exit 1
    fi
    
    if [[ ! -x "$DINGO_CLI" ]]; then
        log_error "$DINGO_CLI 没有执行权限或不存在"
        exit 1
    fi
}

# 验证 Store ID 是否存在于 Store Map 中
verify_store_exists() {
    local store_id="$1"
    local store_map="$DEFAULT_STORE_MAP"
    
    if [[ ! -f "$store_map" ]]; then
        log_warn "Store Map 文件不存在: $store_map，跳过 Store 验证"
        return 0
    fi
    
    if grep -q "^${store_id}[[:space:]]" "$store_map"; then
        local store_info=$(grep "^${store_id}[[:space:]]" "$store_map" | head -1)
        local store_type=$(echo "$store_info" | awk '{print $2}')
        local store_addr=$(echo "$store_info" | awk '{print $3}')
        
        log_info "目标 Store 信息:"
        log_info "  Store ID: $store_id"
        log_info "  Type: $store_type"
        log_info "  Address: $store_addr"
        return 0
    else
        log_error "Store ID $store_id 不存在于 Store Map 文件中"
        log_error "可用的 Store ID 列表:"
        awk '{print $1}' "$store_map" | head -20 >&2
        return 3
    fi
}

# 执行添加 Peer Region
add_peer_region() {
    local region_id="$1"
    local store_id="$2"
    
    local cmd="$DINGO_CLI AddPeerRegion --store_id=$store_id --region_id=$region_id --verify_peer_on_store=true"
    
    echo ""
    log_info "执行命令: $cmd"
    echo "----------------------------------------"
    
    local output
    local exit_code
    
    set +e
    output=$($cmd 2>&1)
    exit_code=$?
    set -e
    
    echo "$output"
    echo "----------------------------------------"
    
    if [[ $exit_code -eq 0 ]]; then
        # 检查输出中是否包含成功标志
        if echo "$output" | grep -qi "success\|ok\|added"; then
            log_info "✅ AddPeerRegion 执行成功"
            return 0
        else
            log_warn "命令执行完成，但请确认输出结果"
            return 0
        fi
    else
        log_error "AddPeerRegion 执行失败，退出码: $exit_code"
        return 2
    fi
}

# 主函数
main() {
    parse_args "$@"
    
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "[DEBUG] 调试模式已启用" >&2
        echo "[DEBUG] 参数: REGION_ID=$REGION_ID, STORE_ID=$STORE_ID" >&2
    fi
    
    validate_args
    
    echo ""
    echo "========================================="
    log_info "开始添加 Peer Region"
    echo "========================================="
    log_info "Region ID: $REGION_ID"
    log_info "Store ID: $STORE_ID"
    echo "========================================="
    
    # 验证 Store 是否存在
    log_info "步骤1: 验证 Store ID"
    if ! verify_store_exists "$STORE_ID"; then
        exit 3
    fi
    
    # 执行添加操作
    log_info "步骤2: 执行 AddPeerRegion"
    if add_peer_region "$REGION_ID" "$STORE_ID"; then
        echo ""
        echo "========================================="
        log_info "✅ Peer Region 添加完成"
        echo "========================================="
        exit 0
    else
        echo ""
        echo "========================================="
        log_error "❌ Peer Region 添加失败"
        echo "========================================="
        exit 2
    fi
}

# 执行主函数
main "$@"
