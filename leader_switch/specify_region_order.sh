#!/bin/bash

# 用法: ./specify_region_order.sh <输入文件> [输出文件]
# 示例: ./specify_region_order.sh 80001.txt
# 示例: ./specify_region_order.sh 80001.txt 80001_order.txt

# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "错误: 缺少输入文件"
    echo "用法: $0 <输入文件> [输出文件]"
    echo "示例: $0 80001.txt"
    echo "示例: $0 80001.txt 80001_order.txt"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.*}_order.txt}"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"

# 执行处理
#awk '
#{
#    if (match($0, /\[([0-9]{8} [0-9:.]+)\]/, t)) {
#        print t[1], $0
#    }
#}
#' "$INPUT_FILE" \
#| sort -k1,1 \
#| cut -d' ' -f2- > "$OUTPUT_FILE"


awk '
{
    if (match($0, /\[([0-9]{8} [0-9:.]+)\]/, t)) {
        # 打印时间戳用于排序，但后面会去掉
        print t[1] "|" $0
    }
}
' "$INPUT_FILE" \
| sort -k1,1 \
| cut -d'|' -f2- > "$OUTPUT_FILE"


# 检查执行结果
if [ $? -eq 0 ]; then
    echo "处理完成！"
    echo "输出行数: $(wc -l < "$OUTPUT_FILE")"
else
    echo "处理失败！"
    exit 1
fi


