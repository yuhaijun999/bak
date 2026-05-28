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
readonly COLOR_RESET='\033[0m'

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
    echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} $*"
}

# 显示帮助信息
show_usage() {
    cat << EOF
使用方法: $SCRIPT_NAME <region_id> <leader_id> [store_map_file]

检查指定 Region 在指定 Store 上的状态，并验证所有副本的可用性

参数:
    region_id       Region ID（必须为大于0的整数）
    leader_id       Leader Store ID（必须为大于0的整数）
    store_map_file  Store Map 文件路径（可选，默认: $DEFAULT_STORE_MAP）

示例:
    $SCRIPT_NAME 80013 30003
    $SCRIPT_NAME 80013 30003 /tmp/store.txt
    $SCRIPT_NAME -h

退出状态码:
    0  成功，所有副本正常
    1  参数错误
    2  Region 不存在或查询失败
    3  存在不可用的副本

EOF
}

# 检查参数
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# 获取参数
REGION_ID="${1:-}"
LEADER_ID="${2:-}"
STORE_MAP_FILE="${3:-$DEFAULT_STORE_MAP}"

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
check_leader_in_store_map() {
    local leader_id="$1"
    local store_map="$2"
    
    if grep -q "^${leader_id}[[:space:]]" "$store_map"; then
        local store_info=$(grep "^${leader_id}[[:space:]]" "$store_map" | head -1)
        local store_type=$(echo "$store_info" | awk '{print $2}')
        local store_addr=$(echo "$store_info" | awk '{print $3}')
        
        log_info "Leader Store $leader_id 存在"
        log_info "  Type: $store_type"
        log_info "  Address: $store_addr"
        echo "$store_addr"
        return 0
    else
        log_error "Leader Store $leader_id 不存在于 Store Map 文件中"
        echo "可用的 Store ID 列表:"
        awk '{print $1}' "$store_map" | head -20
        exit 1
    fi
}

# 查询 Region 状态
query_region_status() {
    local store_addr="$1"
    local region_id="$2"
    local output_file="/tmp/region_status_${region_id}_$$.tmp"
    
    log_debug "执行: $DINGO_CLI QueryRegionStatus --store_addrs=$store_addr --region_ids=$region_id"
    
    if $DINGO_CLI QueryRegionStatus --store_addrs="$store_addr" --region_ids="$region_id" > "$output_file" 2>&1; then
        if grep -q "not exist" "$output_file"; then
            log_warn "Region $region_id 在 Store $store_addr 上不存在"
            rm -f "$output_file"
            return 2
        elif grep -q "leader_id:" "$output_file"; then
            # 成功获取到信息
            cat "$output_file"
            rm -f "$output_file"
            return 0
        else
            log_warn "查询返回了未知响应"
            cat "$output_file" >&2
            rm -f "$output_file"
            return 1
        fi
    else
        log_error "执行命令失败"
        cat "$output_file" >&2
        rm -f "$output_file"
        return 1
    fi
}

# 从输出中提取 leader_id
extract_leader_id() {
    local output_file="$1"
    grep "leader_id:" "$output_file" | awk '{print $2}' | head -1
}

# 从输出中提取所有 peer 的 store_id 和地址
extract_peers() {
    local output_file="$1"
    local peers=()
    
    # 使用 awk 解析 peers 块
    awk '
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
    ' "$output_file"
}

# 检查所有 peer 的可用性
check_all_peers() {
    local region_id="$1"
    local leader_addr="$2"
    local output_file="$3"
    local failed_peers=()
    
    # 提取 leader_id
    local actual_leader_id=$(extract_leader_id "$output_file")
    log_info "查询结果中的 leader_id: $actual_leader_id"
    
    # 验证 leader_id 是否匹配
    if [[ "$actual_leader_id" != "$LEADER_ID" ]]; then
        log_warn "指定的 leader_id ($LEADER_ID) 与实际查询到的 leader_id ($actual_leader_id) 不一致"
    fi
    
    # 提取所有 peers
    log_info "提取所有副本信息..."
    local peers_data=$(extract_peers "$output_file")
    
    if [[ -z "$peers_data" ]]; then
        log_error "未能提取到任何 peer 信息"
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
        
        # 查询该 Store 上的 Region 状态
        local peer_output="/tmp/peer_check_${region_id}_${store_id}_$$.tmp"
        
        if $DINGO_CLI QueryRegionStatus --store_addrs="$addr" --region_ids="$region_id" > "$peer_output" 2>&1; then
            if grep -q "leader_id:" "$peer_output"; then
                local peer_leader_id=$(grep "leader_id:" "$peer_output" | awk '{print $2}')
                log_info "  ✅ Store $store_id ($addr) 上 Region 存在，leader_id: $peer_leader_id"
            elif grep -q "not exist" "$peer_output"; then
                log_error "  ❌ Store $store_id ($addr) 上 Region $region_id 不存在"
                failed_peers+=("$store_id:$addr")
            else
                log_warn "  ⚠️ Store $store_id ($addr) 返回未知响应"
            fi
        else
            log_error "  ❌ 无法连接到 Store $store_id ($addr)"
            failed_peers+=("$store_id:$addr")
        fi
        
        rm -f "$peer_output"
        echo ""
    done <<< "$peers_data"
    
    # 输出失败结果
    if [[ ${#failed_peers[@]} -gt 0 ]]; then
        echo ""
        echo "========================================="
        log_error "发现不可用的副本:"
        for failed in "${failed_peers[@]}"; do
            local store_id=$(echo "$failed" | cut -d':' -f1)
            local addr=$(echo "$failed" | cut -d':' -f2-)
            echo "  - Store ID: $store_id, Address: $addr"
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
    echo "========================================="
    
    # 1. 验证 leader_id 存在于 Store Map
    log_info "步骤1: 验证 Leader Store 存在性"
    LEADER_ADDR=$(check_leader_in_store_map "$LEADER_ID" "$STORE_MAP_FILE")
    
    # 2. 查询 Region 状态
    echo ""
    log_info "步骤2: 查询 Region 状态"
    QUERY_OUTPUT="/tmp/region_query_${REGION_ID}_$$.tmp"
    
    if ! query_region_status "$LEADER_ADDR" "$REGION_ID" > "$QUERY_OUTPUT"; then
        log_error "查询 Region $REGION_ID 失败"
        rm -f "$QUERY_OUTPUT"
        exit 2
    fi
    
    # 显示查询结果的关键信息
    echo ""
    log_info "步骤3: 分析查询结果"
    echo "----------------------------------------"
    grep -E "^(id:|leader_id:|state:)" "$QUERY_OUTPUT" | head -5
    echo "----------------------------------------"
    
    # 3. 检查所有 peer 的可用性
    check_all_peers "$REGION_ID" "$LEADER_ADDR" "$QUERY_OUTPUT"
    local result=$?
    
    # 清理临时文件
    rm -f "$QUERY_OUTPUT"
    
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
