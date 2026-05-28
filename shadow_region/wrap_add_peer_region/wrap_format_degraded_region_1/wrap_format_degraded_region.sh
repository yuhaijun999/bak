#!/bin/bash

# 脚本: wrap_format_degraded_region.sh
# 功能: 输出格式化 degraded region 文件 里面包含 degraded 的所有region


# store map
sh get_store_map.sh
sh format_store_map_file.sh


# region map
sh get_region_map.sh

# format degraded region
sh find_degraded_region_from_map.sh
sh format_degraded_region.sh

