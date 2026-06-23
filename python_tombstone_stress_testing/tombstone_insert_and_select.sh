# 创建并写入文件
#!/bin/bash
# tombstone_insert_and_select.sh

echo "=== 开始执行插入操作 ==="
uv run tombstone_insert.py --host 172.30.14.11 --port 3307 --user root --password 123123 --database dingo --count 5000 --update-times 49 --batch-size 100

echo ""
echo "=== 插入完成，开始执行查询操作 (共100次) ==="
for i in $(seq 1 100); do
    echo "--- 第 $i 次查询 ---"
    uv run tombstone_select.py --host 172.30.14.11 --port 3307 --user root --password 123123 --database dingo --select-times 10
	
	if [ $i -lt 100 ]; then
        echo "--- 等待 120 秒后继续 ---"
        sleep 120
    fi
done

echo ""
echo "=== 所有操作执行完毕 ==="

