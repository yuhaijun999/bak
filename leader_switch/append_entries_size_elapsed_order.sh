#!/bin/bash

# 用法: ./append_entries_size_elapsed_order.sh <输入文件> [输出文件]
# 示例: ./append_entries_size_elapsed_order.sh append_entries_size.txt
# 示例: ./append_entries_size_elapsed_order.sh append_entries_size.txt append_entries_size_elapsed_order.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 append_entries_size.txt"
    INPUT_FILE=append_entries_size.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE=append_entries_size_elapsed_order.txt

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"



# 处理流程：提取 elapsed time 并按数值排序
awk '
{
    # 提取 elapsed time
    if (match($0, /elapsed time: ([0-9]+)/, et)) {
        elapsed = et[1] + 0  # 转换为数字
        
        # 输出格式：elapsed_time|原始行
        # 用 %06d 保证排序时数字对齐
        printf "%06d|%s\n", elapsed, $0
    } else {
        # 如果没有匹配到 elapsed time，放在最后
        print "999999|" $0
    }
}
' $INPUT_FILE 2>/dev/null \
| sort -k1,1 -n \
| cut -d'|' -f2- > "$OUTPUT_FILE"


# 统计结果
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "处理完成！共 $LINE_COUNT 行日志"
echo "输出文件: $OUTPUT_FILE"



