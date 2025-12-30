#!/bin/bash

set -euo pipefail

FILE_REGION_IDS="region_ids.txt"
FILE_STORE_MAP="store_map.txt"

if [ $# -gt 0 ]; then
    FILE_REGION_IDS=$1
fi

if [ $# -gt 1 ]; then
    FILE_STORE_MAP=$2
fi

echo "开始读取 ${FILE_REGION_IDS}..."
echo "开始读取 ${FILE_STORE_MAP}..."
echo ""

# 检查文件是否存在
if [ ! -f "$FILE_REGION_IDS" ]; then
    echo "错误: 文件 $FILE 不存在"
    exit 1
fi

# 检查文件是否为空
if [ ! -s "$FILE_REGION_IDS" ]; then
    echo "警告: 文件 $FILE_REGION_IDS 为空"
    exit 0
fi


# 检查文件是否存在
if [ ! -f "$FILE_STORE_MAP" ]; then
    echo "错误: 文件 $FILE_STORE_MAP 不存在"
    exit 1
fi

# 检查文件是否为空
if [ ! -s "$FILE_STORE_MAP" ]; then
    echo "警告: 文件 $FILE_STORE_MAP 为空"
    exit 0
fi


store_ids=()
store_addrs=()

while read -r store_id addr; do
    # 跳过空行
    [[ -z "$store_id" ]] && continue

    store_ids+=("$store_id")
    store_addrs+=("$addr")
done < ${FILE_STORE_MAP}



# 逐行读取文件
line_count=0
while IFS= read -r region_id; do
    # 跳过空行
    [[ -z "$region_id" ]] && continue

    line_count=$((line_count + 1))

    output_store_ids_only=$(./dingodb_client --method=QueryRegion --id=${region_id} 2> /dev/null  | grep -w store_id | sed 's/^[[:space:]]*//' | sort | uniq | awk '{print $2}')

    output_only=()
    #echo "11111 : ${output_store_ids_only}"
    while IFS= read -r id; do
        #echo "处理ID: $id"
        # 这里添加你的处理逻辑
        output_only+=("$id")
    done <<< "$output_store_ids_only"

    #echo "output_only : ${output_only}"

    #echo "读取第 $line_count 行: region_id = $region_id"
    #
    for i in "${!store_ids[@]}"; do
        #echo "$i store_id=${store_ids[$i]}, addr=${store_addrs[$i]}"

        found=false

	    for item in "${output_only[@]}"; do
    	    if [[ "$item" == "${store_ids[$i]}" ]]; then
        	    found=true
        	    break
    	    fi
            #echo "item : ${item}"
        done

        if ! $found; then
            continue
        fi

        output=$(./dingodb_cli QueryRegionStatus --store_addrs="${store_addrs[$i]}"  --region_ids="${region_id}")

        has_state=0
        has_leader=0
        # -------------------------
        # 1. 提取 state
        # -------------------------
        state=$(echo "$output" | awk -F': ' '/^state:/ {print $2}')
        if [[ -n "${state:-}" ]]; then
            #echo "Region state : $state"
            has_state=1
        else
            has_state=0
            continue
        fi

        # -------------------------
        # 2. 提取 leader_id
        # -------------------------
        leader_id=$(echo "$output" | awk -F': ' '/^leader_id:/ {print $2}')

        #echo "Leader ID    : $leader_id"

        if [[ -n "${leader_id:-}" ]]; then
            #echo "Leader ID    : $leader_id"
            has_leader=1
        else
            has_leader=0
        fi

        if ((has_leader)); then
            echo "${region_id} : ${state} ${store_ids[$i]} ${store_addrs[$i]} leader"
        else
            echo "${region_id} : ${state} ${store_ids[$i]} ${store_addrs[$i]}"
        fi
    done
    echo ""

    # 这里可以添加你的处理逻辑
    # 例如: 执行某些命令，调用API等

done < "$FILE_REGION_IDS"

echo ""
echo "读取完成！总共处理了 $line_count 个 region_id"
