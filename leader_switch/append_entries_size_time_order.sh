#!/bin/bash

# 用法: ./append_entries_size_time_order.sh <输入文件> [输出文件]
# 示例: ./append_entries_size_time_order.sh append_entries_size.txt
# 示例: ./append_entries_size_time_order.sh append_entries_size.txt append_entries_size_time_order.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 append_entries_size.txt"
    INPUT_FILE=append_entries_size.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE=append_entries_size_time_order.txt

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"



# 处理流程：提取时间戳并按时间排序
awk '
{
    # 提取日志中的时间戳 [20260228 10:11:33.106348000]
    if (match($0, /\[([0-9]{4}[0-9]{2}[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+)\]/, t)) {
        # 输出格式：时间戳|原始行
        print t[1] "|" $0
    } else {
        # 如果没有匹配到时间戳，放在最后
        print "99999999 99:99:99.999999999|" $0
    }
}
' $INPUT_FILE 2>/dev/null \
| sort -k1,1 \
| cut -d'|' -f2- > "$OUTPUT_FILE"

# 统计结果
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "处理完成！共 $LINE_COUNT 行日志"
echo "输出文件: $OUTPUT_FILE"



