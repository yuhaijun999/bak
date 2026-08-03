DingoDB Region 状态检查脚本说明
================================

注意：本目录中的脚本使用 Bash 语法，请使用 `bash` 或直接使用可执行脚本路径执行，
不要使用 `sh` 强制解释 `exec_region_is_normal.sh`。

一、脚本说明

1. exec_get_store_map.sh

   执行：

       ./dingodb_cli GetStoreMap > exec_get_store_map.txt

   获取当前集群的 Store 信息，包括：

   - Store ID
   - Store Type
   - Store Address
   - Store 状态


2. exec_get_region_map.sh

   执行：

       ./dingodb_cli GetRegionMap > exec_get_region_map.txt

   获取当前集群的 Region 信息，包括：

   - Region ID
   - Region Map 中记录的 Leader ID


3. exec_region_is_normal.sh

   读取以下文件：

       exec_get_store_map.txt
       exec_get_region_map.txt

   脚本会根据 Region 的 Leader ID 找到 Leader 的地址，先对 Leader 执行一次
   查询。然后从 Leader 返回结果的 `peers` 和 `server_location` 中获取该
   Region 的实际副本地址。

   Leader 已经查询过，因此不会重复查询 Leader，只会继续查询其余 peer。
   每个 Region 的副本数量可以是 1 个、2 个或 3 个，脚本会根据实际返回的
   peers 动态检查。

   对 Leader 和其余每个 peer 执行：

       ./dingodb_cli QueryRegionStatus \
           --store_addrs ip:port \
           --region_ids region_id

   如果返回结果中的 `state` 不是 `NORMAL`，则记录错误。

   使用 `--info` 查看正常检查结果：

       bash exec_region_is_normal.sh --info

   或者：

       ./exec_region_is_normal.sh --info

   正常输出示例：

       INFO region_id=80001 store_id=30001 address=172.30.14.14:30001 type=NODE_TYPE_STORE state=NORMAL
       INFO region_id=80001 store_id=30002 address=172.30.14.14:30002 type=NODE_TYPE_STORE state=NORMAL
       INFO region_id=80001 store_id=30003 address=172.30.14.14:30003 type=NODE_TYPE_STORE state=NORMAL leader_id=30003

   其中只有实际 Leader 对应的 Store 输出 `leader_id`。Store 的 Type 会
   根据 peer 的 Store ID 反查 Store Map；如果找不到，则显示为 `UNKNOWN`。

   使用 `--debug` 查看详细查询过程：

       bash exec_region_is_normal.sh --debug

   检查结果会保存到：

       exec_region_is_normal.txt


4. wrap_region_normal.sh

   总控脚本，自动按正确顺序执行：

   1. 获取 Store Map
   2. 获取 Region Map
   3. 检查所有 Region 的 Store 状态

   默认使用 `--info` 模式：

       ./wrap_region_normal.sh


二、推荐使用方式

   在当前 bin 目录执行：

       ./wrap_region_normal.sh


三、错误输出示例

   Store 状态不是 NORMAL：

       ERROR region_id=80001 leader_id=30003 store_id=30002 address=172.30.14.14:30002 type=NODE_TYPE_STORE state=STANDBY expected=NORMAL

   QueryRegionStatus 执行失败：

       ERROR region_id=80002 leader_id=30002 store_id=30002 address=172.30.14.14:30002 type=NODE_TYPE_STORE state=UNKNOWN reason=query_failed exit_code=1

   Leader Store 不存在：

       ERROR region_id=80003 leader_id=39999 store_id=UNKNOWN address=UNKNOWN type=UNKNOWN state=UNKNOWN reason=leader_store_not_found

   脚本最后会输出统计信息：

       Summary: regions=16 checks=48 normal=48 errors=0

   如果存在错误，exec_region_is_normal.sh 会以退出码 1 结束。


四、生成文件

   exec_get_store_map.txt
       GetStoreMap 的输出文件。

   exec_get_region_map.txt
       GetRegionMap 的输出文件。

   exec_region_is_normal.txt
       Region 状态检查结果文件，包括错误信息和统计信息。
