


前置说明：
1. 启动 dingo-store
2. 启动 executor
3. 安装 uv 



使用下面这个脚本
uv run manage_student.py   --host 172.30.14.14   --port 3307   --user root   --password 123123   --database dingo   --count 2147483647  --batch-size 7

命令解释:
--host 172.30.14.14    # ip 地址
--port 3307            # 端口号
--user root            # 用户是 root 
--password 123123      # 密码 123123 
--database dingo       # database  是 dingo 
--count 2147483647     # 一共插入的数据条数 
--batch-size 7         # 每次插入7条

实际上每次插入2M+ 数据
