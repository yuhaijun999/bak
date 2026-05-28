1. wrap_add_peer_region  里面分三个步骤 只能是一个个添加  后创建引起的某个节点的region实际上未创建，需要补, 目前只能一个一个补才行, 因为涉及安装快照重操作
2. wrap_drop_region_permanently 出现影子region, 即coordinator 创建， store/index/document 未创建任何 region 则删除 否则影响全部备份 这个可以一次性搞定
