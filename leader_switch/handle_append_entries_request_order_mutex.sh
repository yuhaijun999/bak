#!/bin/bash

# 用法: ./handle_append_entries_request_order_mutex.sh <输入文件> [输出文件]
# 示例: ./handle_append_entries_request_order_mutex.sh handle_append_entries_request_order.txt
# 示例: ./handle_append_entries_request_order.sh handle_append_entries_request_order.txt handle_append_entries_request_order_mutex.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 handle_append_entries_request_order.txt"
    INPUT_FILE=handle_append_entries_request_order.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE=handle_append_entries_request_order_mutex.txt

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"



# 筛选 mutex 不为 0 的日志行
# 方法1: 将错误输出显示到终端（默认）
awk '
{
    # 提取 mutex 值
    if (match($0, /mutex: ([0-9]+)/, m)) {
        mutex_value = m[1] + 0  # 转换为数字

        # 只保留 mutex > 0 的行
        if (mutex_value > 0) {
            print $0
            count++
        }
    }
}
END {
    print "筛选行数: " count > "/dev/stderr"
}
' $INPUT_FILE > "$OUTPUT_FILE"

# 统计结果
LINE_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo 0)
echo "处理完成！找到 $LINE_COUNT 行 mutex > 0 的日志"

