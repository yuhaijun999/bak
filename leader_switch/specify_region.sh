#!/bin/bash

# 检查参数
if [ $# -eq 0 ]; then
    echo "错误: 请输入region id"
    echo "用法: $0 80001"
    exit 1
fi


# 获取当前目录名（不包含路径）
CURRENT_DIR=$(basename "$PWD")

if [[ "$CURRENT_DIR" = dist* ]]; then
    echo "当前目录是 dist"
else
    echo "当前目录不是 dist"
    echo "当前目录是: $CURRENT_DIR"
    exit 1
fi

# 执行搜索
#rg -w "$1" ./coordinator* ./store* ./index* ./diskann* > "${1}.txt"



# 定义所有可能的目标目录
ALL_DIRS=(
    "coordinator1"
    "coordinator2"
    "coordinator3"
    "diskann1"
    "document1"
    "document2"
    "document3"
    "index1"
    "index2"
    "index3"
    "store1"
    "store2"
    "store3"
)

# 探测实际存在的目录，保存到数组中
EXISTING_DIRS=()
for dir in "${ALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        EXISTING_DIRS+=("$dir")
    fi
done

# 显示探测结果
echo "探测到的目录 (${#EXISTING_DIRS[@]} 个):"
printf "  %s\n" "${EXISTING_DIRS[@]}"
echo ""

# 如果没有目录存在，退出
if [ ${#EXISTING_DIRS[@]} -eq 0 ]; then
    echo "错误: 没有找到任何目标目录"
    exit 1
fi

# 搜索关键字
SEARCH_TERM=$1  # 默认搜索 80198，也可以作为参数传入

echo "搜索关键词: '$SEARCH_TERM'"
echo "在以下目录中搜索:"
printf "  %s\n" "${EXISTING_DIRS[@]}"
echo "==================================="

rg -w "$SEARCH_TERM" "${EXISTING_DIRS[@]}"  > ${SEARCH_TERM}.txt

echo "${SEARCH_TERM}.txt done"

