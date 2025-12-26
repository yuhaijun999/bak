#!/bin/bash



GetRegionMap=$(./dingodb_cli GetRegionMap)

#echo "GetRegionMap : "${GetRegionMap}

# 提取所有id值（只要每行开头的 id= 后面的数字）
echo "${GetRegionMap}"|  awk '{for(i=1;i<=NF;i++) if($i~/^id=/) {split($i,a,"="); print a[2]; break}}' > region_ids.txt
