
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

# 全局变量用于调试模式
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
    $SCRIPT_NAME 80013 30003
    $SCRIPT_NAME 80013 30003 /tmp/store.txt
    $SCRIPT_NAME 80013 30003 --debug
    $SCRIPT_NAME -h

退出状态码:
    0  成功，所有副本正常
    1  参数错误
    2  Region 不存在或查询失败
    3  存在不可用的副本

EOF
}

# 检查参数
DEBUG_MODE=false
STORE_MAP_FILE_ARG=""

# 解析参数
for arg in "$@"; do
    if [[ "$arg" == "--debug" ]]; then
        DEBUG_MODE=true
    fi
done

# 重新获取参数（排除 --debug）
REGION_ID=""
LEADER_ID=""
STORE_MAP_FILE=""

arg_index=1
for arg in "$@"; do
    if [[ "$arg" == "--debug" ]]; then
        continue
    fi

    if [[ $arg_index -eq 1 ]]; then
        REGION_ID="$arg"
    elif [[ $arg_index -eq 2 ]]; then
        LEADER_ID="$arg"
    elif [[ $arg_index -eq 3 ]]; then
        STORE_MAP_FILE="$arg"
    fi
    ((arg_index++))
done

# 设置默认值
STORE_MAP_FILE="${STORE_MAP_FILE:-$DEFAULT_STORE_MAP}"

# 启用调试模式时显示参数信息
if [[ "$DEBUG_MODE" == true ]]; then
    log_info_debug "调试模式已启用"
    log_info_debug "参数解析结果:"
    log_info_debug "  REGION_ID=$REGION_ID"
    log_info_debug "  LEADER_ID=$LEADER_ID"
    log_info_debug "  STORE_MAP_FILE=$STORE_MAP_FILE"
fi

# 检查帮助
if [[ "${REGION_ID:-}" == "-h" ]] || [[ "${REGION_ID:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# 检查 region_id 和 leader_id 是否提供
if [[ -z "$REGION_ID" ]] || [[ -z "$LEADER_ID" ]]; then
    log_error "必须提供 region_id 和 leader_id"
    show_usage
    exit 1
fi

# 检查 region_id 是否为大于0的整数
if ! [[ "$REGION_ID" =~ ^[0-9]+$ ]] || [[ "$REGION_ID" -le 0 ]]; then
    log_error "region_id 必须是大于0的整数，当前值: $REGION_ID"
    exit 1
fi

# 检查 leader_id 是否为大于0的整数
if ! [[ "$LEADER_ID" =~ ^[0-9]+$ ]] || [[ "$LEADER_ID" -le 0 ]]; then
    log_error "leader_id 必须是大于0的整数，当前值: $LEADER_ID"
    exit 1
fi

# 检查 Store Map 文件
if [[ ! -f "$STORE_MAP_FILE" ]]; then
    log_error "Store Map 文件不存在: $STORE_MAP_FILE"
    exit 1
fi

if [[ ! -r "$STORE_MAP_FILE" ]]; then
    log_error "Store Map 文件不可读: $STORE_MAP_FILE"
    exit 1
fi

# 检查 dingodb_cli 是否存在
if [[ ! -f "$DINGO_CLI" ]]; then
    log_error "找不到 $DINGO_CLI，请确保在 dingodb_cli 所在目录执行此脚本"
    exit 1
fi

if [[ ! -x "$DINGO_CLI" ]]; then
    log_error "$DINGO_CLI 没有执行权限"
    exit 1
fi

# 验证 leader_id 是否存在于 Store Map 中
# 返回值：成功返回0，失败返回1
# 同时通过全局变量返回地址
get_leader_address() {
    local leader_id="$1"
    local store_map="$2"

    log_debug "在 Store Map 文件中查找 Leader ID: $leader_id"

    # 查找 Store 信息
    local store_line=$(grep "^${leader_id}[[:space:]]" "$store_map" | head -1)

    if [[ -z "$store_line" ]]; then
        log_error "Leader Store $leader_id 不存在于 Store Map 文件中"
        log_debug "Store Map 文件内容预览:"
        log_debug "$(head -10 "$store_map" | cat -A)"
        echo "可用的 Store ID 列表:" >&2
        awk '{print $1}' "$store_map" | head -20 >&2
        return 1
    fi

    log_debug "找到 Store 行: $store_line"

    local store_type=$(echo "$store_line" | awk '{print $2}')
    local store_addr=$(echo "$store_line" | awk '{print $3}')

    log_debug "解析结果: Type=$store_type, Address=$store_addr"

    # 日志输出到 stderr，避免被命令替换捕获
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} Leader Store $leader_id 存在" >&2
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET}   Type: $store_type" >&2
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET}   Address: $store_addr" >&2

    # 只输出地址到 stdout
    echo "$store_addr"
    return 0
}

# 查询 Region 状态（返回内容存储在变量中）
query_region_status() {
    local store_addr="$1"
    local region_id="$2"

    local cmd="$DINGO_CLI QueryRegionStatus --store_addrs=$store_addr --region_ids=$region_id"
    log_debug "执行命令: $cmd"

    # 执行命令，捕获输出到变量
    local output
    local exit_code

    set +e
    output=$($cmd 2>&1)
    exit_code=$?
    set -e

    log_debug "命令执行完成，退出码: $exit_code"

    if [[ $exit_code -ne 0 ]]; then
        log_error "命令执行失败，退出码: $exit_code"
        log_error "错误输出:"
        echo "$output" >&2
        return 1
    fi

    # 检查是否包含 "not exist"
    if echo "$output" | grep -q "not exist"; then
        log_warn "Region $region_id 在 Store $store_addr 上不存在"
        log_debug "输出内容: $output"
        return 2
    fi

    # 检查是否包含 "leader_id:"
    if echo "$output" | grep -q "leader_id:"; then
        log_debug "成功获取 Region 状态信息"
        echo "$output"
        return 0
    fi

    # 检查是否有 "Fail to init" 错误
    if echo "$output" | grep -q "Fail to init"; then
        log_error "初始化失败，可能是 Store 地址不正确或服务不可用"
        log_error "Store 地址: $store_addr"
        echo "$output" >&2
        return 1
    fi

    log_warn "查询返回了未知响应"
    echo "$output" >&2
    return 1
}

# 从输出中提取 leader_id
extract_leader_id() {
    local content="$1"
    echo "$content" | grep "leader_id:" | awk '{print $2}' | head -1
}

# 从输出中提取所有 peer 的 store_id 和地址
extract_peers() {
    local content="$1"

    echo "$content" | awk '
        /peers {/ { in_peers=1; store_id=""; host=""; port="" }
        in_peers {
            if (/store_id:/) {
                store_id=$2
            }
            if (/host:/) {
                gsub(/"/, "", $2)
                host=$2
            }
            if (/port:/) {
                port=$2
            }
            if (/}/ && in_peers) {
                if (store_id != "" && host != "" && port != "") {
                    printf "%s %s:%s\n", store_id, host, port
                }
                in_peers=0
                store_id=""; host=""; port=""
            }
        }
    '
}

# 检查所有 peer 的可用性
check_all_peers() {
    local region_id="$1"
    local region_content="$2"
    local failed_peers=()

    # 提取 leader_id
    local actual_leader_id=$(extract_leader_id "$region_content")
    log_info "查询结果中的 leader_id: $actual_leader_id"
    log_debug "提取到的 leader_id: $actual_leader_id"

    # 验证 leader_id 是否匹配
    if [[ "$actual_leader_id" != "$LEADER_ID" ]]; then
        log_warn "指定的 leader_id ($LEADER_ID) 与实际查询到的 leader_id ($actual_leader_id) 不一致"
    fi

    # 提取所有 peers
    log_info "提取所有副本信息..."
    local peers_data=$(extract_peers "$region_content")

    log_debug "提取到的 peers 数据:"
    log_debug "$peers_data"

    if [[ -z "$peers_data" ]]; then
        log_error "未能提取到任何 peer 信息"
        log_debug "原始内容: $region_content"
        return 1
    fi

    echo ""
    echo "========================================="
    echo "副本信息列表:"
    echo "========================================="

    local peer_count=0
    while IFS= read -r peer; do
        if [[ -n "$peer" ]]; then
            ((peer_count++))
            local store_id=$(echo "$peer" | awk '{print $1}')
            local addr=$(echo "$peer" | awk '{print $2}')

            echo "$peer_count. Store ID: $store_id, Address: $addr"
            log_debug "  Peer $peer_count: store_id=$store_id, addr=$addr"
        fi
    done <<< "$peers_data"

    echo "========================================="
    echo ""

    # 检查每个 peer 的可用性
    log_info "开始检查每个副本的可用性..."
    echo ""

    while IFS= read -r peer; do
        if [[ -z "$peer" ]]; then
            continue
        fi

        local store_id=$(echo "$peer" | awk '{print $1}')
        local addr=$(echo "$peer" | awk '{print $2}')

        log_info "检查 Store $store_id ($addr)..."
        log_debug "执行查询命令: $DINGO_CLI QueryRegionStatus --store_addrs=$addr --region_ids=$region_id"

        local peer_output
        local peer_exit_code

        set +e
        peer_output=$($DINGO_CLI QueryRegionStatus --store_addrs="$addr" --region_ids="$region_id" 2>&1)
        peer_exit_code=$?
        set -e

        log_debug "Peer 查询完成，退出码: $peer_exit_code"
        log_debug "Peer 输出: $peer_output"

        if [[ $peer_exit_code -eq 0 ]] && echo "$peer_output" | grep -q "leader_id:"; then
            local peer_leader_id=$(echo "$peer_output" | grep "leader_id:" | awk '{print $2}')
            log_info "  ✅ Store $store_id ($addr) 上 Region 存在，leader_id: $peer_leader_id"
            log_debug "  Peer 检查成功: leader_id=$peer_leader_id"
        elif echo "$peer_output" | grep -q "not exist"; then
            log_error "  ❌ Store $store_id ($addr) 上 Region $region_id 不存在"
            failed_peers+=("$store_id:$addr")
            log_debug "  Peer 检查失败: Region 不存在"
        elif echo "$peer_output" | grep -q "Fail to init"; then
            log_error "  ❌ 无法连接到 Store $store_id ($addr) - 初始化失败"
            failed_peers+=("$store_id:$addr")
            log_debug "  Peer 检查失败: 初始化失败"
        else
            log_error "  ❌ Store $store_id ($addr) 查询失败"
            failed_peers+=("$store_id:$addr")
            log_debug "  Peer 检查失败: 未知错误"
        fi

        echo ""
    done <<< "$peers_data"

    if [[ ${#failed_peers[@]} -gt 0 ]]; then
        echo ""
        echo "========================================="
        log_error "发现不可用的副本:"
        for failed in "${failed_peers[@]}"; do
            local store_id=$(echo "$failed" | cut -d':' -f1)
            local addr=$(echo "$failed" | cut -d':' -f2-)
            echo "  - Store ID: $store_id, Address: $addr"
            log_debug "  不可用副本: store_id=$store_id, addr=$addr"
        done
        echo "========================================="
        return 3
    fi

    log_info "所有副本检查通过！"
    return 0
}

# 主函数
main() {
    echo ""
    echo "========================================="
    log_info "开始检查 Region $REGION_ID (Leader Store: $LEADER_ID)"
    if [[ "$DEBUG_MODE" == true ]]; then
        log_info_debug "调试模式: 开启"
        log_info_debug "Store Map 文件: $STORE_MAP_FILE"
    fi
    echo "========================================="

    # 1. 验证 leader_id 存在于 Store Map 并获取地址
    log_info "步骤1: 验证 Leader Store 存在性"
    log_debug "调用 get_leader_address 函数"

    local LEADER_ADDR
    LEADER_ADDR=$(get_leader_address "$LEADER_ID" "$STORE_MAP_FILE")

    if [[ -z "$LEADER_ADDR" ]]; then
        log_error "无法获取 Leader Store 地址"
        exit 1
    fi

    log_debug "获取到的 Leader 地址: $LEADER_ADDR"

    # 2. 查询 Region 状态
    echo ""
    log_info "步骤2: 查询 Region 状态"
    log_debug "准备查询 Region $REGION_ID 在 Store $LEADER_ADDR 上的状态"

    local QUERY_OUTPUT
    if ! QUERY_OUTPUT=$(query_region_status "$LEADER_ADDR" "$REGION_ID"); then
        local query_exit_code=$?
        log_error "查询 Region $REGION_ID 失败 (退出码: $query_exit_code)"
        log_error "请检查:"
        log_error "  1. Store 地址 $LEADER_ADDR 是否正确"
        log_error "  2. 网络连接是否正常"
        log_error "  3. dingodb 服务是否正常运行"
        exit 2
    fi

    log_debug "查询成功，输出长度: ${#QUERY_OUTPUT} 字符"

    # 显示查询结果的关键信息
    echo ""
    log_info "步骤3: 分析查询结果"
    echo "----------------------------------------"
    echo "$QUERY_OUTPUT" | grep -E "^(id:|leader_id:|state:)" | head -5 || echo "无法解析输出"
    echo "----------------------------------------"

    if [[ "$DEBUG_MODE" == true ]]; then
        log_info_debug "完整查询输出:"
        log_info_debug "========== 开始 =========="
        echo "$QUERY_OUTPUT" >&2
        log_info_debug "========== 结束 =========="
    fi

    # 3. 检查所有 peer 的可用性
    check_all_peers "$REGION_ID" "$QUERY_OUTPUT"
    local result=$?

    echo ""
    echo "========================================="
    if [[ $result -eq 0 ]]; then
        log_info "检查完成: Region $REGION_ID 所有副本均正常"
    else
        log_error "检查完成: Region $REGION_ID 存在不可用的副本"
    fi
    echo "========================================="

    exit $result
}

# 执行主函数
main "$@"
