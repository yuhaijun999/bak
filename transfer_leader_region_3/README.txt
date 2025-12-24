1. exec create_table.sh                     region id 80001 3个节点 
2. exec modify_region_meta_standy.sh        修改各个节点的normal 为 standby
3. exec query_region_status.sh              查询各个region 状态是不是 standby
4. exec transfer_leader_region.sh           不加force 尝试 切换leader , 一定都失败
5. exec query_region_status.sh              查询各个region 哪个是Leader
6. exec transfer_leader_region_force.sh     加force 三个命令中仅仅执行一个命令即可， 避开原来是leader 节点 否则失败
7. exec modify_region_meta_normal.sh        将三个节点的状态设置为normal
8. exec add_data                            添加数据
