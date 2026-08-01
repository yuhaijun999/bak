#!/usr/bin/env bash

set -u

REGION_MAP_FILE="exec_get_region_map.txt"
STORE_MAP_FILE="exec_get_store_map.txt"
RESULT_FILE="exec_compare_region_leader_match.txt"
DEBUG=0
INFO=0

usage() {
    echo "Usage: $0 [--debug|-d | --info|-i]"
    echo "  --debug, -d  print detailed execution steps"
    echo "  --info, -i   print only the final match status for each region"
}

for arg in "$@"; do
    case "$arg" in
        --debug|-d)
            DEBUG=1
            ;;
        --info|-i)
            INFO=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if ((DEBUG && INFO)); then
    echo "ERROR: --debug and --info cannot be used together" >&2
    exit 1
fi

: > "$RESULT_FILE"

debug_log() {
    ((DEBUG)) || return 0
    printf '[DEBUG] %s\n' "$*" | tee -a "$RESULT_FILE"
}

report_error() {
    printf '%s\n' "$*" >> "$RESULT_FILE"
    if ((DEBUG)); then
        printf '%s\n' "$*"
    fi
}

report_summary() {
    printf '\n%s\n' "$*" >> "$RESULT_FILE"
    if ((DEBUG)); then
        printf '\n%s\n' "$*"
    fi
}

info_log() {
    ((INFO)) || return 0
    printf '%s\n' "$*" | tee -a "$RESULT_FILE"
}

debug_log "region map file: $REGION_MAP_FILE"
debug_log "store map file: $STORE_MAP_FILE"
debug_log "result file: $RESULT_FILE"

if [[ ! -f "$REGION_MAP_FILE" ]]; then
    echo "ERROR: file not found: $REGION_MAP_FILE" >&2
    exit 1
fi

if [[ ! -f "$STORE_MAP_FILE" ]]; then
    echo "ERROR: file not found: $STORE_MAP_FILE" >&2
    exit 1
fi

declare -A store_type_by_id
declare -A store_address_by_id
declare -a store_ids

trim() {
    local value="$1"
    value="${value#${value%%[![:space:]]*}}"
    value="${value%${value##*[![:space:]]}}"
    printf '%s' "$value"
}

# Parse rows such as:
# | 30003 | NODE_TYPE_STORE | 172.30.14.14:30003:0 | STORE_NORMAL | ... |
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*([0-9]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\| ]]; then
        store_id="${BASH_REMATCH[1]}"
        store_type="$(trim "${BASH_REMATCH[2]}")"
        raw_address="$(trim "${BASH_REMATCH[3]}")"

        # The CLI address is ip:port:0; QueryRegionStatus needs ip:port.
        address="${raw_address%:*}"

        store_type_by_id["$store_id"]="$store_type"
        store_address_by_id["$store_id"]="$address"
        store_ids+=("$store_id")
        debug_log "store: id=$store_id type=$store_type address=$address"
    fi
done < "$STORE_MAP_FILE"

debug_log "loaded ${#store_ids[@]} stores"

success_count=0
failed_count=0
total_count=0

while IFS= read -r line; do
    if [[ ! "$line" =~ id=([0-9]+).*leader=([0-9]+) ]]; then
        continue
    fi

    region_id="${BASH_REMATCH[1]}"
    expected_leader_id="${BASH_REMATCH[2]}"
    ((total_count += 1))
    debug_log "region: id=$region_id expected_leader_id=$expected_leader_id"

    expected_type="${store_type_by_id[$expected_leader_id]-}"
    if [[ -z "$expected_type" ]]; then
        ((failed_count += 1))
        report_error "ERROR: region_id=$region_id region_map_leader_id=$expected_leader_id actual_leader_id=UNKNOWN (leader store not found in store map)"
        info_log "region_id=$region_id leader=$expected_leader_id MISMATCH leader_id: UNKNOWN store_type=UNKNOWN"
        continue
    fi

    debug_log "region $region_id leader store type: $expected_type"
    actual_leader_id=""
    matched=0

    # Probe the region-map leader first, then all stores of the same type.
    for candidate_id in "$expected_leader_id" "${store_ids[@]}"; do
        if [[ "${store_type_by_id[$candidate_id]-}" != "$expected_type" ]]; then
            continue
        fi

        candidate_address="${store_address_by_id[$candidate_id]-}"
        [[ -z "$candidate_address" ]] && continue

        debug_log "query: ./dingodb_cli QueryRegionStatus --store_addrs $candidate_address --region_ids $region_id"
        query_output="$(./dingodb_cli QueryRegionStatus \
            --store_addrs "$candidate_address" \
            --region_ids "$region_id" 2>&1 || true)"

        if ((DEBUG)); then
            debug_log "query output from store $candidate_id:"
            while IFS= read -r output_line; do
                printf '[DEBUG]   %s\n' "$output_line" | tee -a "$RESULT_FILE"
            done <<< "$query_output"
        fi

        detected_leader_id="$(printf '%s\n' "$query_output" | \
            sed -n 's/^[[:space:]]*leader_id:[[:space:]]*\([0-9][0-9]*\).*$/\1/p' | head -n 1)"

        if [[ -n "$detected_leader_id" ]]; then
            actual_leader_id="$detected_leader_id"
            debug_log "detected leader_id=$actual_leader_id from store $candidate_id"
            if [[ "$actual_leader_id" == "$expected_leader_id" ]]; then
                matched=1
                debug_log "region $region_id matched"
                break
            fi
        else
            debug_log "no leader_id found in response from store $candidate_id"
        fi
    done

    if ((matched)); then
        ((success_count += 1))
        info_log "region_id=$region_id leader=$expected_leader_id MATCH leader_id: $actual_leader_id store_type=$expected_type"
    else
        ((failed_count += 1))
        if [[ -z "$actual_leader_id" ]]; then
            actual_leader_id="UNKNOWN"
        fi
        report_error "ERROR: region_id=$region_id region_map_leader_id=$expected_leader_id actual_leader_id=$actual_leader_id"
        info_log "region_id=$region_id leader=$expected_leader_id MISMATCH leader_id: $actual_leader_id store_type=$expected_type"
    fi
done < "$REGION_MAP_FILE"

report_summary "Summary: total=$total_count success=$success_count failed=$failed_count"
