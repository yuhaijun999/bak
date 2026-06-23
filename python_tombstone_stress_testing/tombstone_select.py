# /// script
# dependencies = [
#     "pymysql",
# ]
# ///
# uv run tombstone_select.py --host 172.30.14.14 --port 3307 --user root --password 123123 --database dingo --select-times 100

import argparse
import sys
import pymysql
import time


def select_test(db_config, select_times):
    """执行多次 SELECT * FROM student 查询并统计耗时"""
    
    connection = pymysql.connect(**db_config)
    
    try:
        with connection.cursor() as cursor:
            print(f"\n[查询测试] 将执行 {select_times} 次 SELECT * FROM student 查询")
            print(f"[数据表] student")
            print(f"[查询类型] 全表扫描（不输出结果内容）")
            print("-" * 80)
            
            # 存储每次查询的耗时（毫秒）
            elapsed_times_ms = []
            
            for i in range(1, select_times + 1):
                # 开始计时（毫秒精度）
                start_time = time.perf_counter()
                
                # 执行查询
                cursor.execute("SELECT * FROM student")
                
                # 获取结果但不输出内容（只获取行数以确认查询完成）
                rows = cursor.fetchall()
                row_count = len(rows)
                
                # 结束计时
                end_time = time.perf_counter()
                elapsed_ms = (end_time - start_time) * 1000  # 转换为毫秒
                elapsed_times_ms.append(elapsed_ms)
                
                # 实时显示进度
                sys.stdout.write(
                    f"\r[进度] 第 {i}/{select_times} 次查询 | "
                    f"耗时: {elapsed_ms:.3f} ms | "
                    f"返回行数: {row_count}"
                )
                sys.stdout.flush()
            
            print("\n" + "-" * 80)
            
            # 统计信息
            if elapsed_times_ms:
                total_time_ms = sum(elapsed_times_ms)
                avg_time_ms = total_time_ms / select_times
                min_time_ms = min(elapsed_times_ms)
                max_time_ms = max(elapsed_times_ms)
                
                # 计算标准差
                variance = sum((t - avg_time_ms) ** 2 for t in elapsed_times_ms) / select_times
                stddev_ms = variance ** 0.5
                
                print(f"\n[统计结果]")
                print(f"  - 总查询次数: {select_times}")
                print(f"  - 总耗时: {total_time_ms:.3f} ms ({total_time_ms / 1000:.3f} 秒)")
                print(f"  - 平均耗时: {avg_time_ms:.3f} ms")
                print(f"  - 最小耗时: {min_time_ms:.3f} ms")
                print(f"  - 最大耗时: {max_time_ms:.3f} ms")
                print(f"  - 标准差: {stddev_ms:.3f} ms")
                print(f"  - 每次查询平均返回行数: {row_count} 行")
                
                # 输出分位数信息
                sorted_times = sorted(elapsed_times_ms)
                p50 = sorted_times[int(select_times * 0.5)]
                p90 = sorted_times[int(select_times * 0.9)]
                p95 = sorted_times[int(select_times * 0.95)]
                p99 = sorted_times[int(select_times * 0.99)]
                
                print(f"\n[分位数统计]")
                print(f"  - P50 (中位数): {p50:.3f} ms")
                print(f"  - P90: {p90:.3f} ms")
                print(f"  - P95: {p95:.3f} ms")
                print(f"  - P99: {p99:.3f} ms")
                
    except Exception as e:
        print(f"\n[查询失败] 错误: {e}")
        raise e
    finally:
        connection.close()


def verify_table_exists(db_config):
    """验证表是否存在并返回行数"""
    connection = pymysql.connect(**db_config)
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM student")
            result = cursor.fetchone()
            row_count = result[0] if result else 0
            print(f"[表验证] 表 student 存在，当前总行数: {row_count}")
            return row_count
    except Exception as e:
        print(f"[表验证失败] 错误: {e}")
        print("[提示] 请确保表 student 已经通过 manage_student.py 创建")
        return 0
    finally:
        connection.close()


def main():
    parser = argparse.ArgumentParser(
        description="DingoDB 全表扫描性能压测工具（SELECT * FROM student）"
    )
    parser.add_argument("--host", required=True, help="数据库 IP 地址")
    parser.add_argument("--port", type=int, default=3307, help="数据库端口, 默认 3307")
    parser.add_argument("--user", required=True, help="数据库用户名")
    parser.add_argument("--password", default="123123", help="数据库密码, 默认 123123")
    parser.add_argument("--database", default="dingo", help="数据库名, 默认 dingo")
    parser.add_argument("--select-times", type=int, required=True, help="需要执行的 SELECT 查询次数")

    args = parser.parse_args()

    db_config = {
        "host": args.host,
        "port": args.port,
        "user": args.user,
        "password": args.password,
        "database": args.database,
    }

    print("=" * 80)
    print("[SELECT 压测工具]")
    print(f"[配置参数] host={args.host}, port={args.port}, database={args.database}")
    print(f"[查询次数] {args.select_times}")
    print("=" * 80)

    # 验证表是否存在
    row_count = verify_table_exists(db_config)
    if row_count == 0:
        print("[警告] 表 student 为空或不存在，查询测试可能返回空结果")
    
    print()
    
    # 执行查询测试
    try:
        select_test(db_config, args.select_times)
        print("\n" + "=" * 80)
        print("[测试完成]")
        print("=" * 80)
    except Exception as e:
        print(f"\n[测试失败] {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
