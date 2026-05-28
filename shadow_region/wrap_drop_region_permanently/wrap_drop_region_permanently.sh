#!/bin/bash

# 脚本: wrap_drop_region_permanently.sh
# 功能: 批量删除 Shadow Region（仅删除真正的孤儿 Region） 从get_region_map 到挑选合适的孤儿region 再到删除


sh get_region_map.sh
sh find_shadow_region.sh
sh drop_region_permanently.sh
