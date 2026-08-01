DingoDB Region Leader 检查脚本说明
====================================

一、脚本说明

1. exec_get_store_map.sh

   执行以下命令：

       ./dingodb_cli GetStoreMap > exec_get_store_map.txt

   作用：
   获取当前集群的 Store 信息，包括 Store ID、Store 类型、IP 地址和端口，
   并将结果保存到 exec_get_store_map.txt。


2. exec_get_region_map.sh

   执行以下命令：

       ./dingodb_cli GetRegionMap > exec_get_region_map.txt

   作用：
   获取当前集群的 Region 信息，包括 Region ID 和 region map 中记录的 leader ID，
   并将结果保存到 exec_get_region_map.txt。


3. exec_compare_region_leader_match.sh

   作用：
   读取以下两个文件：

       exec_get_store_map.txt
       exec_get_region_map.txt

   根据 Region Map 中的 leader ID 找到对应的 Store 地址和 Store 类型，
   然后执行 QueryRegionStatus 检查实际的 leader ID，比较两者是否一致。

   使用 --info 模式时，只输出简要的检查结果，例如：

       region_id=80001 leader=30003 MATCH leader_id: 30003 store_type=NODE_TYPE_STORE

   检查结果会保存到：

       exec_compare_region_leader_match.txt


4. wrap_region_leader_match.sh

   总控脚本，自动按正确顺序执行以上三个脚本，并使用 --info 模式进行比对。


二、执行顺序

   必须按照以下顺序执行：

       1. exec_get_store_map.sh
       2. exec_get_region_map.sh
       3. exec_compare_region_leader_match.sh --info

   因为第三个脚本依赖前两个脚本生成的文本文件。


三、推荐执行方式

   在当前目录执行：

       ./wrap_region_leader_match.sh

   总控脚本会自动完成 Store Map 获取、Region Map 获取和 Region Leader 比对。


四、单独查看详细调试信息

   如果需要查看每个 Region 的详细探测过程，可以单独执行：

       ./exec_compare_region_leader_match.sh --debug

   --debug 模式会显示实际执行的 QueryRegionStatus 命令、命令输出和 leader 匹配过程。


五、生成的文件

   exec_get_store_map.txt
       GetStoreMap 命令的输出文件。

   exec_get_region_map.txt
       GetRegionMap 命令的输出文件。

   exec_compare_region_leader_match.txt
       Region Leader 比对的错误明细和统计结果。
