#!/bin/bash

# 脚本: drop_region_permanently.sh
# 功能: 批量删除 Shadow Region（仅删除真正的孤儿 Region）

set -e

# 默认文件
INPUT_FILE="${1:-./find_shadow_region.txt}"
OUTPUT_FILE="${2:-./drop_region_permanently.txt}"
DRY_RUN=false

# 检查 --dry-run 参数
if [[ "$1" == "--dry-run" ]] || [[ "$2" == "--dry-run" ]] || [[ "$3" == "--dry-run" ]]; then
    DRY_RUN=true
    # 重新设置文件参数
    if [[ "$1" != "--dry-run" ]] && [[ -n "$1" ]]; then
        INPUT_FILE="$1"
    fi
    if [[ "$2" != "--dry-run" ]] && [[ -n "$2" ]]; then
        OUTPUT_FILE="$2"
    fi
fi

# 检查输入文件
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "错误: 输入文件不存在: $INPUT_FILE"
    exit 1
fi

# 检查 dingodb_cli
if [[ ! -x "./dingodb_cli" ]]; then
    echo "错误: ./dingodb_cli 不存在或不可执行"
    exit 1
fi

echo ""
echo "========================================="
echo "开始批量删除 Shadow Region"
if [[ "$DRY_RUN" == true ]]; then
    echo "模式: DRY-RUN (试运行，不会实际删除)"
fi
echo "========================================="

# 清空输出文件
> "$OUTPUT_FILE"
echo "# id name result error_code error_msg" >> "$OUTPUT_FILE"
echo "# 执行时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
[[ "$DRY_RUN" == true ]] && echo "# 模式: DRY-RUN" >> "$OUTPUT_FILE"
echo "# ========================================" >> "$OUTPUT_FILE"

# 统计
TOTAL=0
SUCCESS=0
FAILED=0

# 读取文件并处理
while IFS= read -r line; do
    # 跳过空行
    [[ -z "$line" ]] && continue
    
    # 提取 id
    if [[ "$line" =~ ^id=([0-9]+) ]]; then
        REGION_ID="${BASH_REMATCH[1]}"
    else
        continue
    fi
    
    # 提取 name
    if [[ "$line" =~ name=([^[:space:]]+) ]]; then
        REGION_NAME="${BASH_REMATCH[1]}"
    else
        REGION_NAME="unknown"
    fi
    
    TOTAL=$((TOTAL + 1))
    
    echo ""
    echo "----------------------------------------"
    echo "[$TOTAL] 处理 Region: $REGION_ID ($REGION_NAME)"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY-RUN] 将执行: ./dingodb_cli DropRegionPermanently --id=$REGION_ID"
        echo "$REGION_ID $REGION_NAME DRY-RUN - -" >> "$OUTPUT_FILE"
        SUCCESS=$((SUCCESS + 1))
        echo "  ✅ DRY-RUN 完成"
    else
        echo "  执行: ./dingodb_cli DropRegionPermanently --id=$REGION_ID"
        
        # 执行删除并捕获输出
        OUTPUT=$(./dingodb_cli DropRegionPermanently --id="$REGION_ID" 2>&1)
        EXIT_CODE=$?
        
        # 解析输出，提取错误码和错误信息
        ERROR_CODE=""
        ERROR_MSG=""
        
        # 检查是否有 error 块
        if echo "$OUTPUT" | grep -q "errcode:"; then
            ERROR_CODE=$(echo "$OUTPUT" | grep "errcode:" | head -1 | sed 's/.*errcode: //' | sed 's/ .*//')
            ERROR_MSG=$(echo "$OUTPUT" | grep "errmsg:" | head -1 | sed 's/.*errmsg: "//' | sed 's/".*//')
        fi
        
        # 判断结果
        if [[ -z "$ERROR_CODE" ]]; then
            # 没有错误，成功
            echo "$REGION_ID $REGION_NAME SUCCESS - -" >> "$OUTPUT_FILE"
            SUCCESS=$((SUCCESS + 1))
            echo "  ✅ 删除成功"
        elif [[ "$ERROR_CODE" == "EREGION_NOT_FOUND" ]]; then
            # Region 不存在，也算成功（已经是删除状态）
            echo "$REGION_ID $REGION_NAME NOT_EXIST $ERROR_CODE $ERROR_MSG" >> "$OUTPUT_FILE"
            SUCCESS=$((SUCCESS + 1))
            echo "  ⚠️ Region 不存在 (已删除)"
        else
            # 其他错误，失败
            echo "$REGION_ID $REGION_NAME FAILED $ERROR_CODE $ERROR_MSG" >> "$OUTPUT_FILE"
            FAILED=$((FAILED + 1))
            echo "  ❌ 删除失败: $ERROR_CODE - $ERROR_MSG"
        fi
    fi
done < "$INPUT_FILE"

# 显示结果
echo ""
echo "========================================="
echo "执行完成"
echo "========================================="
echo "输入文件: $INPUT_FILE"
echo "输出文件: $OUTPUT_FILE"
echo "========================================="
echo "统计:"
echo "  总数: $TOTAL"
echo "  成功: $SUCCESS"
echo "  失败: $FAILED"
echo "========================================="

# 显示失败的记录
if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo "失败的记录:"
    grep "FAILED" "$OUTPUT_FILE" 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo "========================================="
    exit 1
fi

exit 0
