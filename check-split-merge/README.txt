
# 将脚本放在dingo-store/dist 下

# 单节点
1. exec create_single_region.sh     在/home/server/work/dingo-sdk/build/bin
下执行 创建单个节点 并灌入数据 默认region id = 80001
2. exec txn_count_80001.sh          查看灌入数据的条数
3. exec split_region.sh             生成 将 80001 分成 80001 和 80002 
4. exec txn_count_80001.sh txn_count_80002.sh 分别查看条数
5. exec merge_region.sh             合并 80001 80002
6. exec drop_region.sh              删除 80001

# 三节点
1. exec create_three_region.sh     在/home/server/work/dingo-sdk/build/bin
下执行 创建三个节点 并灌入数据 默认region id = 80001
2. exec txn_count_80001.sh          查看灌入数据的条数
3. exec split_region.sh             生成 将 80001 分成 80001 和 80002 
4. exec txn_count_80001.sh txn_count_80002.sh 分别查看条数
5. exec merge_region.sh             合并 80001 80002
6. exec drop_region.sh              删除 80001
