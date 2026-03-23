#!/bin/bash

# 用法: ./on_leader_start_term_repeat.sh <输入文件> [输出文件]
# 示例: ./on_leader_start_term_repeat.sh on_leader_start_term.txt
# 示例: ./on_leader_start_term_repeat.sh on_leader_start_term.txt on_leader_start_term_repeat.txt

INPUT_FILE=
# 检查输入文件参数
if [ $# -lt 1 ]; then
    echo "警告: 缺少输入文件 默认使用 on_leader_start_term.txt"
    INPUT_FILE=on_leader_start_term.txt
else
    INPUT_FILE=$1
fi

OUTPUT_FILE="${2:-${INPUT_FILE%.*}_repeat.txt}"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 输入文件 '$INPUT_FILE' 不存在"
    exit 1
fi

echo "处理文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"



# 仅仅输出重复的region 
awk '
{
    match($0,/region\(([0-9]+)\)/,r)
    match($0,/term\(([0-9]+)\)/,t)
    print r[1], t[1], $0
}
' ${INPUT_FILE} \
| sort -n -k1,1 -k2,2 \
| awk '
{
    region=$1
    $1=$2=""
    sub(/^  */,"")

    if (region == prev_region) {
        # 重复
        if (count == 1) {
            # 第二条出现时，给第一条补 *
            lines[1] = lines[1] " *"
        }
        lines[++count] = $0
    } else {
        # 切换 region
        if (count > 1) {
            for (i=1; i<=count; i++) print lines[i]
            print ""    # 不同 region 之间空一行（可删）
        }
        delete lines
        count=1
        lines[1]=$0
    }
    prev_region=region
}
END {
    if (count > 1) {
        for (i=1; i<=count; i++) print lines[i]
    }
}
' > ./${OUTPUT_FILE}


# 检查执行结果
if [ $? -eq 0 ]; then
    echo "处理完成！"
    echo "输出行数: $(wc -l < "$OUTPUT_FILE")"
else
    echo "处理失败！"
    exit 1
fi


