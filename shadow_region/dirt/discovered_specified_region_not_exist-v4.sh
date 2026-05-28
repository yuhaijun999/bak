
#!/bin/bash

##############################################################################
# 脚本名称: discovered_specified_region_not_exist.sh
# 功能描述: 检查指定 Region 在指定 Store 上的状态，并验证所有副本的可用性
# 使用方法: ./discovered_specified_region_not_exist.sh <region_id> <leader_id> [store_map_file]
#          store_map_file 默认: ./format_store_map_file.txt
##############################################################################

set -o errexit
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

log_info_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo -e "${COLOR_CYAN}[DEBUG-INFO]${COLOR_RESET} $*"
    fi
}

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $SCRIPT_NAME <region_id> <leader_id> [store_map_file] [--debug]

检查指定 Region 在指定 Store 上的状态，并验证所有副本的可用性

参数:
    region_id       Region ID（必须为大于0的整数）
    leader_id       Leader Store ID（必须为大于0的整数）
    store_map_file  Store Map 文件路径（可选，默认: $DEFAULT_STORE_MAP）
    --debug         启用调试模式，显示详细执行信息

示例:
    $SCRIPT_NAME 80013 30001
    $SCRIPT_NAME 80013 30001 /tmp/store.txt
    $SCRIPT_NAME 80013 30001 --debug

退出状态码:
    0  成功，所有副本正常
    1  参数错误
    2  Region 不存在或查询失败
    3  存在不可用的副本

EOF
}

# 解析参数
parse_args() {
    DEBUG_MODE=false
    REGION_ID=""
    LEADER_ID=""
    STORE_MAP_FILE=""

    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            DEBUG_MODE=true
        fi
    done

    # 重新获取参数（排除 --debug）
    local args=()
    for arg in "$@"; do
        if [[ "$arg" != "--debug" ]]; then
            args+=("$arg")
        fi
    done

    REGION_ID="${args[0]:-}"
    LEADER_ID="${args[1]:-}"
    STORE_MAP_FILE="${args[2]:-}"
    STORE_MAP_FILE="${STORE_MAP_FILE:-$DEFAULT_STORE_MAP}"
}

# 验证参数
validate_args() {
    if [[ "$REGION_ID" == "-h" ]] || [[ "$REGION_ID" == "--help" ]]; then
        show_usage
        exit 0
    fi

    if [[ -z "$REGION_ID" ]] || [[ -z "$LEADER_ID" ]]; then
        log_error "必须提供 region_id 和 leader_id"
        show_usage
        exit 1
    fi

    if ! [[ "$REGION_ID" =~ ^[0-9]+$ ]] || [[ "$REGION_ID" -le 0 ]]; then
        log_error "region_id 必须是大于0的整数，当前值: $REGION_ID"
        exit 1
    fi

    if ! [[ "$LEADER_ID" =~ ^[0-9]+$ ]] || [[ "$LEADER_ID" -le 0 ]]; then
        log_error "leader_id 必须是大于0的整数，当前值: $LEADER_ID"
        exit 1
    fi

    if [[ ! -f "$STORE_MAP_FILE" ]]; then
        log_error "Store Map 文件不存在: $STORE_MAP_FILE"
        exit 1
    fi

    if [[ ! -x "$DINGO_CLI" ]]; then
        log_error "$DINGO_CLI 没有执行权限或不存在"
        exit 1
    fi
}

# 获取 Leader Store 地址
get_leader_address() {
    local leader_id="$1"
    local store_map="$2"

    local store_line=$(grep "^${leader_id}[[:space:]]" "$store_map" | head -1)

    if [[ -z "$store_line" ]]; then
        log_error "Leader Store $leader_id 不存在于 Store Map 文件中"
        echo "可用的 Store ID 列表:" >&2
        awk '{print $1}' "$store_map" | head -20 >&2
        return 1
    fi

    local store_type=$(echo "$store_line" | awk '{print $2}')
    local store_addr=$(echo "$store_line" | awk '{print $3}')

    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} Leader Store $leader_id 存在" >&2
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET}   Type: $store_type" >&2
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET}   Address: $store_addr" >&2

    echo "$store_addr"
    return 0
}

# 查询 Region 状态
query_region_status() {
    local store_addr="$1"
    local region_id="$2"

    local cmd="$DINGO_CLI QueryRegionStatus --store_addrs=$store_addr --region_ids=$region_id"
    log_debug "执行命令: $cmd"

    local output
    local exit_code

    set +e
    output=$($cmd 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -ne 0 ]]; then
        log_error "命令执行失败，退出码: $exit_code"
        echo "$output" >&2
        return 1
    fi

    if echo "$output" | grep -q "not exist"; then
        log_warn "Region $region_id 在 Store $store_addr 上不存在"
        return 2
    fi

    if echo "$output" | grep -q "leader_id:"; then
        echo "$output"
        return 0
    fi

    log_warn "查询返回了未知响应"
    echo "$output" >&2
    return 1
}

# 从输出中提取所有 peer 的信息（store_id 和 server_location）
extract_peers() {
    local content="$1"

    # 使用更简单的方法：逐行解析
    local in_peers=false
    local current_store_id=""
    local current_host=""
    local current_port=""
    local result=""

    while IFS= read -r line; do
        # 检测 peers 块开始
        if echo "$line" | grep -q "peers {"; then
            in_peers=true
            current_store_id=""
            current_host=""
            current_port=""
            continue
        fi

        # 在 peers 块内
        if [[ "$in_peers" == true ]]; then
            # 提取 store_id
            if echo "$line" | grep -q "store_id:"; then
                current_store_id=$(echo "$line" | awk '{print $2}')
                log_debug "  找到 store_id: $current_store_id"
            fi

            # 提取 server_location 中的 host（排除 raft_location）
            if echo "$line" | grep -q "host:" && ! echo "$line" | grep -q "raft_location"; then
                current_host=$(echo "$line" | awk '{print $2}' | tr -d '"')
                log_debug "  找到 host: $current_host"
            fi

            # 提取 server_location 中的 port（排除 raft_location）
            if echo "$line" | grep -q "port:" && ! echo "$line" | grep -q "raft_location"; then
                current_port=$(echo "$line" | awk '{print $2}')
                log_debug "  找到 port: $current_port"
            fi

            # 检测 peers 块结束
            if echo "$line" | grep -q "^[[:space:]]*}"; then
                if [[ -n "$current_store_id" ]] && [[ -n "$current_host" ]] && [[ -n "$current_port" ]]; then
                    result="${result}${current_store_id} ${current_host}:${current_port}"$'\n'
                    log_debug "  完整 peer: $current_store_id $current_host:$current_port"
                fi
                in_peers=false
            fi
        fi
    done <<< "$content"

    echo "$result"
}

# 从输出中提取 leader_id
extract_leader_id() {
    local content="$1"
    echo "$content" | grep "leader_id:" | awk '{print $2}' | head -1
}

# 检查单个 peer 上的 Region 状态
check_peer_region() {
    local store_id="$1"
    local addr="$2"
    local region_id="$3"
    local is_leader="$4"

    local leader_mark=""
    if [[ "$is_leader" == "true" ]]; then
        leader_mark=" (Leader)"
    fi

    log_info "检查 Store $store_id ($addr)$leader_mark..."

    local output
    local exit_code

    set +e
    output=$($DINGO_CLI QueryRegionStatus --store_addrs="$addr" --region_ids="$region_id" 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]] && echo "$output" | grep -q "leader_id:"; then
        local peer_leader_id=$(echo "$output" | grep "leader_id:" | awk '{print $2}')
        log_info "  ✅ Store $store_id ($addr) 上 Region $region_id 存在，leader_id: $peer_leader_id"
        return 0
    elif echo "$output" | grep -q "not exist"; then
        log_error "  ❌ Store $store_id ($addr) 上 Region $region_id 不存在"
        return 1
    elif echo "$output" | grep -q "Fail to init"; then
        log_error "  ❌ 无法连接到 Store $store_id ($addr) - 服务不可用"
        return 1
    else
        log_error "  ❌ Store $store_id ($addr) 查询失败"
        log_debug "输出: $output"
        return 1
    fi
}

# 主函数
main() {
    parse_args "$@"

    if [[ "$DEBUG_MODE" == true ]]; then
        log_info_debug "调试模式已启用"
        log_info_debug "参数: REGION_ID=$REGION_ID, LEADER_ID=$LEADER_ID, STORE_MAP_FILE=$STORE_MAP_FILE"
    fi

    validate_args

    echo ""
    echo "========================================="
    log_info "开始检查 Region $REGION_ID (期望 Leader: $LEADER_ID)"
    echo "========================================="

    # 步骤1: 获取 Leader Store 地址
    log_info "步骤1: 验证 Leader Store 存在性"
    local LEADER_ADDR
    LEADER_ADDR=$(get_leader_address "$LEADER_ID" "$STORE_MAP_FILE")

    if [[ -z "$LEADER_ADDR" ]]; then
        log_error "无法获取 Leader Store 地址"
        exit 1
    fi

    # 步骤2: 从指定的 Leader Store 查询 Region 状态
    echo ""
    log_info "步骤2: 从 Store $LEADER_ADDR 查询 Region $REGION_ID 状态"

    local QUERY_OUTPUT
    if ! QUERY_OUTPUT=$(query_region_status "$LEADER_ADDR" "$REGION_ID"); then
        log_error "查询 Region $REGION_ID 失败"
        exit 2
    fi

    # 显示查询结果摘要
    echo ""
    log_info "步骤3: 解析查询结果"
    echo "----------------------------------------"
    echo "$QUERY_OUTPUT" | grep -E "^(id:|leader_id:|state:)" | head -5
    echo "----------------------------------------"

    # 提取实际的 leader_id
    local ACTUAL_LEADER_ID=$(extract_leader_id "$QUERY_OUTPUT")
    log_info "实际查询到的 leader_id: $ACTUAL_LEADER_ID"

    if [[ "$ACTUAL_LEADER_ID" != "$LEADER_ID" ]]; then
        log_warn "期望的 leader_id ($LEADER_ID) 与实际 leader_id ($ACTUAL_LEADER_ID) 不一致"
    fi

    # 步骤4: 提取所有 peers
    log_info "提取所有副本信息..."
    local PEERS_DATA=$(extract_peers "$QUERY_OUTPUT")

    if [[ -z "$PEERS_DATA" ]]; then
        log_error "未能提取到任何 peer 信息"
        if [[ "$DEBUG_MODE" == true ]]; then
            log_debug "查询输出内容:"
            log_debug "$QUERY_OUTPUT"
        fi
        exit 1
    fi

    # 显示 peers 列表
    echo ""
    echo "========================================="

    # 将 PEERS_DATA 转换为数组
    local peers_array=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            peers_array+=("$line")
        fi
    done <<< "$PEERS_DATA"

    local peer_count=${#peers_array[@]}
    echo "副本列表 (共 $peer_count 个):"
    echo "========================================="

    for i in "${!peers_array[@]}"; do
        local peer="${peers_array[$i]}"
        local store_id=$(echo "$peer" | awk '{print $1}')
        local addr=$(echo "$peer" | awk '{print $2}')
        local is_leader="false"
        if [[ "$store_id" == "$ACTUAL_LEADER_ID" ]]; then
            is_leader="true"
        fi
        local leader_flag=""
        if [[ "$is_leader" == "true" ]]; then
            leader_flag=" (Leader)"
        fi
        echo "$((i+1)). Store ID: $store_id, Address: $addr$leader_flag"
    done
    echo "========================================="
    echo ""

    # 步骤5: 检查每个 peer
    log_info "步骤4: 检查每个副本上的 Region 状态"
    echo ""

    local failed_peers=()
    local checked_count=0

    for peer in "${peers_array[@]}"; do
        local store_id=$(echo "$peer" | awk '{print $1}')
        local addr=$(echo "$peer" | awk '{print $2}')
        local is_leader="false"

        if [[ "$store_id" == "$ACTUAL_LEADER_ID" ]]; then
            is_leader="true"
        fi

        ((checked_count++))

        if check_peer_region "$store_id" "$addr" "$REGION_ID" "$is_leader"; then
            log_info "  ✅ 检查通过"
        else
            failed_peers+=("$store_id:$addr")
        fi
        echo ""
    done

    # 输出最终结果
    echo "========================================="
    echo "检查汇总:"
    echo "  总副本数: $checked_count"
    echo "  通过数: $((checked_count - ${#failed_peers[@]}))"
    echo "  失败数: ${#failed_peers[@]}"
    echo "========================================="

    if [[ ${#failed_peers[@]} -gt 0 ]]; then
        echo ""
        log_error "不可用的副本:"
        for failed in "${failed_peers[@]}"; do
            local store_id=$(echo "$failed" | cut -d':' -f1)
            local addr=$(echo "$failed" | cut -d':' -f2-)
            echo "  - Store ID: $store_id, Address: $addr"
        done
        echo "========================================="
        log_error "检查完成: Region $REGION_ID 存在不可用的副本"
        echo "========================================="
        exit 3
    else
        log_info "所有副本检查通过！"
        echo "========================================="
        log_info "检查完成: Region $REGION_ID 所有副本均正常"
        echo "========================================="
        exit 0
    fi
}

# 执行主函数
main "$@"

