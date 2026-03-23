#!/bin/bash

# 用法: ./on_leader_start_term_gt_2.sh <输入文件> [输出文件]
# 示例: ./on_leader_start_term_gt_2.sh on_leader_start_term.txt
# 示例: ./on_leader_start_term_gt_2.sh on_leader_start_term.txt on_leader_start_term_gt_2.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 on_leader_start_term.txt"
    INPUT_FILE=on_leader_start_term.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE=on_leader_start_term_gt_2.txt

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"

# 处理流程
awk '
{
    if (match($0, /\[([0-9]{4}[0-9]{2}[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+)\]/, time) &&
        match($0, /term\(([0-9]+)\)/, term)) {

        # 关键修改：转换为数字再比较
        if (term[1] + 0 > 2) {
            print time[1] "|" $0
        }
    }
}
' $INPUT_FILE 2>/dev/null \
| sort -k1,1 \
| cut -d'|' -f2- > "$OUTPUT_FILE"



# 统计结果
LINE_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "处理完成！找到 $LINE_COUNT 行 term > 2 的日志"


