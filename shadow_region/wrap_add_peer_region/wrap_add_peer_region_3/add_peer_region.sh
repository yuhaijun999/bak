
#!/bin/bash

##############################################################################
# 脚本名称: add_peer_region.sh
# 功能描述: 向指定 Store 添加 Peer Region
# 使用方法: ./add_peer_region.sh <region_id> <store_id> [--force] [--debug]
#          region_id: Region ID（必须为大于0的整数）
#          store_id: Store ID（必须为大于0的整数）
#          --force: 强制执行，跳过前置检查
##############################################################################

set -o nounset
set -o pipefail

# 脚本配置
readonly SCRIPT_NAME=$(basename "$0")
readonly DINGO_CLI="./dingodb_cli"
readonly DEFAULT_STORE_MAP="./format_store_map_file.txt"
readonly TIMEOUT_SECONDS=10

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# 全局变量
DEBUG_MODE=false
FORCE_MODE=false

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
使用方法: $SCRIPT_NAME <region_id> <store_id> [--force] [--debug]

向指定 Store 添加 Peer Region

参数:
    region_id       Region ID（必须为大于0的整数）
    store_id        Store ID（必须为大于0的整数）
    --force         强制执行，跳过前置检查
    --debug         启用调试模式，显示详细执行信息

示例:
    $SCRIPT_NAME 80013 30003
    $SCRIPT_NAME 80013 30003 --force
    $SCRIPT_NAME 80013 30003 --debug

注意:
    添加 Peer Region 前会检查该 Store 是否已经是该 Region 的 Peer
    如果是，则不会重复添加

退出状态码:
    0  成功
    1  参数错误
    2  执行命令失败
    3  Store ID 不在 Store Map 中
    4  Store 已经是该 Region 的 Peer（非强制模式）

EOF
}

# 解析参数
parse_args() {
    DEBUG_MODE=false
    FORCE_MODE=false
    REGION_ID=""
    STORE_ID=""

    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            DEBUG_MODE=true
        fi
        if [[ "$arg" == "--force" ]]; then
            FORCE_MODE=true
        fi
    done

    local args=()
    for arg in "$@"; do
        if [[ "$arg" != "--debug" ]] && [[ "$arg" != "--force" ]]; then
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

# 查询 Region 信息，获取当前 Peers
query_region_peers() {
    local region_id="$1"
    local leader_addr="$2"

    local cmd="$DINGO_CLI QueryRegionStatus --store_addrs=$leader_addr --region_ids=$region_id"
    log_debug "执行命令: $cmd"

    local output
    local exit_code

    set +e
    output=$($cmd 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -ne 0 ]]; then
        log_error "查询 Region $region_id 失败"
        return 1
    fi

    if echo "$output" | grep -q "not exist"; then
        log_error "Region $region_id 不存在"
        return 2
    fi

    # 提取所有 peer 的 store_id
    local peers=$(echo "$output" | grep "store_id:" | awk '{print $2}' | sort -u | tr '\n' ' ')
    echo "$peers"
    return 0
}

# 获取该 Region 的 Leader Store 地址
get_region_leader_addr() {
    local region_id="$1"

    # 从 Store Map 中尝试所有 Store，找到能返回该 Region 信息的 Store
    local store_map="$DEFAULT_STORE_MAP"

    if [[ ! -f "$store_map" ]]; then
        log_error "无法获取 Region Leader 信息，Store Map 文件不存在"
        return 1
    fi

    # 遍历所有 Store，找到能查询到该 Region 的 Store
    while IFS= read -r line; do
        local store_id=$(echo "$line" | awk '{print $1}')
        local store_addr=$(echo "$line" | awk '{print $3}')

        local cmd="$DINGO_CLI QueryRegionStatus --store_addrs=$store_addr --region_ids=$region_id"
        local output
        set +e
        output=$($cmd 2>&1)
        local exit_code=$?
        set -e

        if [[ $exit_code -eq 0 ]] && echo "$output" | grep -q "leader_id:"; then
            echo "$store_addr"
            return 0
        fi
    done < "$store_map"

    log_error "无法找到能查询到 Region $region_id 的 Store"
    return 1
}

# 检查 Store 是否已经是该 Region 的 Peer
check_store_is_peer() {
    local region_id="$1"
    local store_id="$2"

    log_info "检查 Store $store_id 是否已经是 Region $region_id 的 Peer..."

    # 获取 Region 的 Leader 地址
    local leader_addr
    leader_addr=$(get_region_leader_addr "$region_id")

    if [[ -z "$leader_addr" ]]; then
        log_warn "无法获取 Region $region_id 的 Leader 地址，跳过检查"
        return 0
    fi

    log_debug "使用 Leader 地址: $leader_addr"

    # 查询当前 Peers
    local current_peers
    current_peers=$(query_region_peers "$region_id" "$leader_addr")

    if [[ -z "$current_peers" ]]; then
        log_warn "无法获取 Region $region_id 的当前 Peers，跳过检查"
        return 0
    fi

    log_info "Region $region_id 当前 Peers: [${current_peers}]"

    # 检查目标 Store 是否已在 Peers 中
    if echo "$current_peers" | grep -q "\b${store_id}\b"; then
        log_warn "Store $store_id 已经是 Region $region_id 的 Peer"
        return 4
    fi

    log_info "Store $store_id 不是 Region $region_id 的 Peer，可以添加"
    return 0
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

    # 判断执行结果
    # 检查是否包含失败标志
    if echo "$output" | grep -qi "failed"; then
        log_error "AddPeerRegion 执行失败"

        # 提取错误信息
        local error_msg=$(echo "$output" | grep -oP 'error_msg=\K[^,]+' | head -1)
        local error_code=$(echo "$output" | grep -oP 'error_code=\K[^,]+' | head -1)

        if [[ -n "$error_code" ]] && [[ -n "$error_msg" ]]; then
            log_error "错误代码: $error_code"
            log_error "错误信息: $error_msg"
        fi

        return 2
    fi

    # 检查是否包含成功标志
    if echo "$output" | grep -qi "success\|ok\|added\|start"; then
        # 还需要检查是否有错误码
        if echo "$output" | grep -q "error_code=" && ! echo "$output" | grep -q "error_code=0"; then
            log_error "AddPeerRegion 执行失败（返回了错误码）"
            return 2
        fi
        log_info "✅ AddPeerRegion 执行成功"
        return 0
    fi

    # 检查退出码
    if [[ $exit_code -eq 0 ]]; then
        log_warn "命令执行完成，但无法确定是否成功，请检查输出"
        return 0
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
        echo "[DEBUG] 参数: REGION_ID=$REGION_ID, STORE_ID=$STORE_ID, FORCE_MODE=$FORCE_MODE" >&2
    fi

    validate_args

    echo ""
    echo "========================================="
    log_info "开始添加 Peer Region"
    echo "========================================="
    log_info "Region ID: $REGION_ID"
    log_info "Store ID: $STORE_ID"
    if [[ "$FORCE_MODE" == true ]]; then
        log_warn "强制模式已启用，将跳过前置检查"
    fi
    echo "========================================="

    # 步骤1: 验证 Store 是否存在
    log_info "步骤1: 验证 Store ID"
    if ! verify_store_exists "$STORE_ID"; then
        exit 3
    fi

    # 步骤2: 检查 Store 是否已经是 Peer（非强制模式）
    if [[ "$FORCE_MODE" != true ]]; then
        log_info "步骤2: 检查 Store 是否已经是 Peer"
        if check_store_is_peer "$REGION_ID" "$STORE_ID"; then
            local check_result=$?
            if [[ $check_result -eq 4 ]]; then
                echo ""
                echo "========================================="
                log_error "❌ Store $STORE_ID 已经是 Region $REGION_ID 的 Peer"
                echo "========================================="
                log_info "如需强制添加，请使用 --force 参数"
                echo "========================================="
                exit 4
            fi
        fi
    else
        log_warn "步骤2: 跳过 Peer 检查（强制模式）"
    fi

    # 步骤3: 执行添加操作
    log_info "步骤3: 执行 AddPeerRegion"
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
