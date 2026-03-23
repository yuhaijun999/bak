#!/bin/bash

# 用法: ./append_entries_size_region_order.sh <输入文件> [输出文件]
# 示例: ./append_entries_size_region_order.sh append_entries_size.txt
# 示例: ./append_entries_size_region_order.sh append_entries_size.txt append_entries_size_region_order.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 append_entries_size.txt"
    INPUT_FILE=append_entries_size.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE=append_entries_size_region_order.txt

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"


# 处理流程：提取 region ID 和时间，按 region ID 排序，相同则按时间排序
awk '
{
    # 提取 region ID (方括号中的数字，如 [84667])
    if (match($0, /\[([0-9]+)\]:[0-9.]+:[0-9]+:[0-9]+:[0-9]+/, region) &&
        match($0, /\[([0-9]{4}[0-9]{2}[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+)\]/, time)) {

        region_id = region[1] + 0  # 转换为数字
        log_time = time[1]          # 时间字符串

        # 输出格式：region_id|log_time|原始行
        # region_id 用 %08d 保证数字对齐，时间直接字符串比较
        printf "%08d|%s|%s\n", region_id, log_time, $0
    } else {
        # 如果没有匹配到，放在最后
        print "99999999|99999999 99:99:99.999999999|" $0
    }
}
' $INPUT_FILE 2>/dev/null \
| sort -k1,1 -k2,2 \
| cut -d'|' -f3- > "$OUTPUT_FILE"


# 统计结果
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "处理完成！共 $LINE_COUNT 行日志"
echo "输出文件: $OUTPUT_FILE"



