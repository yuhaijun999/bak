#!/usr/bin/env bash

set -uo pipefail

REGION_MAP_FILE="exec_get_region_map.txt"
STORE_MAP_FILE="exec_get_store_map.txt"
RESULT_FILE="exec_region_is_normal.txt"

usage() {
    echo "Usage: $0 [--info|-i | --debug|-d]"
    echo "  --info,  -i  print successful NORMAL checks"
    echo "  --debug, -d  print QueryRegionStatus output"
}

DEBUG=0
INFO=0
for arg in "$@"; do
    case "$arg" in
        --info|-i)
            INFO=1
            ;;
        --debug|-d)
            DEBUG=1
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

if [[ ! -f "$REGION_MAP_FILE" ]]; then
    echo "ERROR: file not found: $REGION_MAP_FILE" >&2
    exit 1
fi

if [[ ! -f "$STORE_MAP_FILE" ]]; then
    echo "ERROR: file not found: $STORE_MAP_FILE" >&2
    exit 1
fi

: > "$RESULT_FILE"

declare -A store_type_by_id
declare -A store_address_by_id
declare -a store_ids

trim() {
    local value="$1"
    value="${value#${value%%[![:space:]]*}}"
    value="${value%${value##*[![:space:]]}}"
    printf '%s' "$value"
}

log() {
    printf '%s\n' "$*" | tee -a "$RESULT_FILE"
}

debug_log() {
    ((DEBUG)) || return 0
    printf '[DEBUG] %s\n' "$*" | tee -a "$RESULT_FILE"
}

# Parse rows such as:
# | 30003 | NODE_TYPE_STORE | 172.30.14.14:30003:0 | STORE_NORMAL | ... |
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*([0-9]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\| ]]; then
        store_id="${BASH_REMATCH[1]}"
        store_type="$(trim "${BASH_REMATCH[2]}")"
        raw_address="$(trim "${BASH_REMATCH[3]}")"
        address="${raw_address%:*}"

        store_type_by_id["$store_id"]="$store_type"
        store_address_by_id["$store_id"]="$address"
        store_ids+=("$store_id")
    fi
done < "$STORE_MAP_FILE"

total_regions=0
total_checks=0
normal_count=0
error_count=0

while IFS= read -r line; do
    if [[ ! "$line" =~ ^[[:space:]]*id=([0-9]+).*leader=([0-9]+) ]]; then
        continue
    fi

    region_id="${BASH_REMATCH[1]}"
    leader_id="${BASH_REMATCH[2]}"
    ((total_regions += 1))

    leader_type="${store_type_by_id[$leader_id]-}"
    if [[ -z "$leader_type" ]]; then
        ((error_count += 1))
        log "ERROR region_id=$region_id leader_id=$leader_id store_id=UNKNOWN address=UNKNOWN type=UNKNOWN state=UNKNOWN reason=leader_store_not_found"
        continue
    fi

    debug_log "region_id=$region_id leader_id=$leader_id type=$leader_type"

    for store_id in "${store_ids[@]}"; do
        [[ "${store_type_by_id[$store_id]-}" == "$leader_type" ]] || continue

        address="${store_address_by_id[$store_id]-}"
        if [[ -z "$address" ]]; then
            ((error_count += 1))
            log "ERROR region_id=$region_id leader_id=$leader_id store_id=$store_id address=UNKNOWN type=$leader_type state=UNKNOWN reason=store_address_not_found"
            continue
        fi

        ((total_checks += 1))
        debug_log "query: ./dingodb_cli QueryRegionStatus --store_addrs $address --region_ids $region_id"

        query_status=0
        if query_output="$(./dingodb_cli QueryRegionStatus \
            --store_addrs "$address" \
            --region_ids "$region_id" 2>&1)"; then
            query_status=0
        else
            query_status=$?
        fi

        if ((DEBUG)); then
            while IFS= read -r output_line; do
                printf '[DEBUG]   %s\n' "$output_line" | tee -a "$RESULT_FILE"
            done <<< "$query_output"
        fi

        state="$(awk '/^[[:space:]]*state:[[:space:]]*/ { print $2; exit }' <<< "$query_output")"
        detected_leader_id="$(awk '/^[[:space:]]*leader_id:[[:space:]]*/ { print $2; exit }' <<< "$query_output")"
        if ((query_status != 0)); then
            ((error_count += 1))
            log "ERROR region_id=$region_id leader_id=$leader_id store_id=$store_id address=$address type=$leader_type state=${state:-UNKNOWN} reason=query_failed exit_code=$query_status"
        elif [[ "$state" == "NORMAL" ]]; then
            ((normal_count += 1))
            if ((INFO)); then
                if [[ "$detected_leader_id" == "$store_id" ]]; then
                    log "INFO region_id=$region_id store_id=$store_id address=$address type=$leader_type state=$state leader_id=$detected_leader_id"
                else
                    log "INFO region_id=$region_id store_id=$store_id address=$address type=$leader_type state=$state"
                fi
            fi
            debug_log "OK region_id=$region_id store_id=$store_id address=$address type=$leader_type state=NORMAL"
        else
            ((error_count += 1))
            log "ERROR region_id=$region_id leader_id=$leader_id store_id=$store_id address=$address type=$leader_type state=${state:-UNKNOWN} expected=NORMAL"
        fi
    done

    if ((INFO)); then
        printf '\n' | tee -a "$RESULT_FILE"
    fi
done < "$REGION_MAP_FILE"

log "Summary: regions=$total_regions checks=$total_checks normal=$normal_count errors=$error_count"

if ((error_count > 0)); then
    exit 1
fi

exit 0
