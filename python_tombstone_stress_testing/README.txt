
主要用户测试 插入数据和查询数据的性能 用于 rocksdb tombstone 的性能优化

前置说明：
1. 启动 dingo-store
2. 启动 executor
3. 安装 uv


4. 插入数据:
使用下面这个脚本
uv run tombstone_insert.py --host 172.30.14.11 --port 3307 --user root --password 123123 --database dingo --count 5000 --update-times 49 --batch-size 100

命令解释:
--host 172.30.14.14    # ip 地址
--port 3307            # 端口号
--user root            # 用户是 root
--password 123123      # 密码 123123
--database dingo       # database  是 dingo
--count 5000           # 一共插入的数据条不重复的数据
--update-times 49      # 一共更新49次
--batch-size 100       # 每次插入100条

实际上每条数据一共插入了50次 1次插入 49次更新


5. 查询数据
uv run tombstone_select.py --host 172.30.14.11 --port 3307 --user root --password 123123 --database dingo --select-times 10

命令解释:
--host 172.30.14.14    # ip 地址
--port 3307            # 端口号
--user root            # 用户是 root
--password 123123      # 密码 123123
--database dingo       # database  是 dingo
--select-times 10      # 一共查询了10次

实际查询的次数为10次
