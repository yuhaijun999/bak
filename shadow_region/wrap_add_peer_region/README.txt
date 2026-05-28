

wrap_format_degraded_region_1 # 主要是获取format_degraded_region.txt 和 format_store_map_file.txt
wrap_discovered_specified_region_not_exist_2  从 format_degraded_region.txt 获取 一行  指定 region id  和 leader 查看 哪个store id 没有副本
wrap_add_peer_region_3  根据2 获取到 region id  和  store  id 添加 
目前还不知道什么时候算OK了
