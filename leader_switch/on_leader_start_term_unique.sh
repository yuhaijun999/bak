#!/bin/bash

# 用法: ./on_leader_start_term_unique.sh <输入文件> [输出文件]
# 示例: ./on_leader_start_term_unique.sh on_leader_start_term_repeat.txt
# 示例: ./on_leader_start_term_repeat.sh on_leader_start_term_repeat.txt on_leader_start_term_unique.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 on_leader_start_term_repeat.txt"
    INPUT_FILE=on_leader_start_term_repeat.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE="on_leader_start_term_unique.txt"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"



grep '\*$' ${INPUT_FILE}  > ${OUTPUT_FILE}

# 检查执行结果
if [ $? -eq 0 ]; then
    echo "处理完成！"
    echo "输出行数: $(wc -l < "$OUTPUT_FILE")"
else
    echo "处理失败！"
    exit 1
fi


