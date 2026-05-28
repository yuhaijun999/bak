
sh wrap_format_degraded_region.sh

实际上生成的内容

server@dingo11 bin [quickBI-v4.0.0] $ cat format_degraded_region.txt
id=80002 name=Benchmark_1776752426807_1[80001]_80002 state=REPLICA_DEGRAED leader=30003
id=80016 name=Benchmark_1776752426807_1[80001]_80003_80016 state=REPLICA_DEGRAED leader=30002
id=80017 name=Benchmark_1776752426807_1[80001]_80003_80017 state=REPLICA_DEGRAED leader=30002
id=80020 name=Benchmark_1776752426807_1[80001]_80013_80020 state=REPLICA_DEGRAED leader=30001
server@dingo11 bin [quickBI-v4.0.0] $


server@dingo11 bin [quickBI-v4.0.0] $ cat format_store_map_file.txt
ID       Type                 Address
31001    NODE_TYPE_INDEX      172.30.14.11:31001
31002    NODE_TYPE_INDEX      172.30.14.11:31002
31003    NODE_TYPE_INDEX      172.30.14.11:31003
30001    NODE_TYPE_STORE      172.30.14.11:30001
30002    NODE_TYPE_STORE      172.30.14.11:30002
30003    NODE_TYPE_STORE      172.30.14.11:30003
33001    NODE_TYPE_DOCUMENT   172.30.14.11:33001
33002    NODE_TYPE_DOCUMENT   172.30.14.11:33002
33003    NODE_TYPE_DOCUMENT   172.30.14.11:33003
server@dingo11 bin [quickBI-v4.0.0] $
