# /// script
# dependencies = [
#     "pymysql",
# ]
# ///
# uv run manage_student.py --host 172.30.14.14 --port 3307 --user root --password 123123 --database dingo --count 10000 --update-times 5 --batch-size 7

import argparse
import sys
import pymysql
import time
from datetime import datetime


def create_table(db_config):
    """创建学生表（不含 text1, text2 字段）"""
    sql = """
    CREATE TABLE IF NOT EXISTS student (
        id BIGINT PRIMARY KEY,
        student_no VARCHAR(20) NOT NULL COMMENT '学号',
        name VARCHAR(50) NOT NULL COMMENT '学生姓名',
        age INT COMMENT '年龄',
        height DOUBLE COMMENT '身高(cm)',
        weight FLOAT(10,2) COMMENT '体重(kg)',
        score DOUBLE(10,2) COMMENT '考试成绩'
    ) ENGINE=TXN_LSM REPLICA=3 COMMENT='学生表';
    """

    cfg = db_config.copy()
    cfg["autocommit"] = True
    connection = pymysql.connect(**cfg)
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
        print("[表结构] 表 student 校验成功（已创建或已存在）")
    finally:
        connection.close()


def insert_or_update_initial_data(db_config, total_count, batch_size):
    """
    初始插入/更新数据（幂等性操作）
    如果数据已存在，则 UPDATE name 后缀自动加1
    如果数据不存在，则 INSERT
    """
    db_config["autocommit"] = False
    connection = pymysql.connect(**db_config)

    try:
        with connection.cursor() as cursor:
            print(f"\n[初始插入/更新] 处理 ID 1 到 {total_count}，每批提交: {batch_size} 条")
            
            insert_list = []      # 需要插入的数据
            update_list = []      # 需要更新的数据 (new_name, id)
            inserted_count = 0
            updated_count = 0
            batch_index = 0
            total_processed = 0

            for i in range(1, total_count + 1):
                row_id = i
                student_no = f"no_{row_id}"
                age = row_id
                height = float(row_id)
                weight = float(row_id)
                score = float(row_id)
                
                # 先查询该 ID 是否存在
                cursor.execute("SELECT name FROM student WHERE id = %s", (row_id,))
                result = cursor.fetchone()
                
                if result:
                    # 数据已存在，需要更新 name 后缀
                    old_name = result[0]
                    # 提取当前后缀数字，格式: no_{id}_{suffix}
                    try:
                        current_suffix = int(old_name.split('_')[-1])
                        new_suffix = current_suffix + 1
                    except (ValueError, IndexError):
                        # 如果格式异常，默认后缀为 1
                        new_suffix = 1
                    
                    new_name = f"no_{row_id}_{new_suffix}"
                    update_list.append((new_name, row_id))
                    updated_count += 1
                else:
                    # 数据不存在，准备插入（首次插入后缀为 1）
                    name = f"no_{row_id}_1"
                    insert_list.append((row_id, student_no, name, age, height, weight, score))
                    inserted_count += 1
                
                total_processed += 1
                
                # 批量执行 INSERT 或 UPDATE
                if (len(insert_list) >= batch_size or len(update_list) >= batch_size or 
                    i == total_count):
                    batch_index += 1
                    
                    # 批量插入
                    if insert_list:
                        insert_sql = """
                            INSERT INTO student (id, student_no, name, age, height, weight, score) 
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """
                        cursor.executemany(insert_sql, insert_list)
                        insert_list = []
                    
                    # 批量更新
                    if update_list:
                        update_sql = "UPDATE student SET name = %s WHERE id = %s"
                        cursor.executemany(update_sql, update_list)
                        update_list = []
                    
                    connection.commit()
                    
                    sys.stdout.write(
                        f"\r[初始处理进度] 批次: {batch_index} | 已处理: {total_processed} / {total_count} "
                        f"(新增: {inserted_count}, 更新: {updated_count})"
                    )
                    sys.stdout.flush()

            print(f"\n[初始处理完成] 总计处理 {total_processed} 条数据 (新增: {inserted_count}, 更新: {updated_count})")

    except Exception as e:
        connection.rollback()
        print(f"\n[初始处理失败] 错误: {e}")
        raise e
    finally:
        connection.close()


def update_data(db_config, total_count, update_times, batch_size):
    """循环更新数据（每次更新 name 字段，后缀递增）"""
    db_config["autocommit"] = False
    connection = pymysql.connect(**db_config)

    try:
        with connection.cursor() as cursor:
            print(f"\n[更新操作] 将对 {total_count} 条数据执行 {update_times} 次更新，每批提交: {batch_size} 条")
            
            total_updated_all_rounds = 0
            
            # 对于每一轮更新
            for update_round in range(1, update_times + 1):
                update_list = []
                batch_index = 0
                updated_count = 0
                
                for i in range(1, total_count + 1):
                    # 查询当前 name 并计算新后缀
                    cursor.execute("SELECT name FROM student WHERE id = %s", (i,))
                    result = cursor.fetchone()
                    
                    if result:
                        old_name = result[0]
                        try:
                            current_suffix = int(old_name.split('_')[-1])
                            new_suffix = current_suffix + 1
                        except (ValueError, IndexError):
                            new_suffix = 1
                        
                        new_name = f"no_{i}_{new_suffix}"
                        update_list.append((new_name, i))
                    else:
                        # 如果数据不存在（异常情况），插入基础数据
                        new_name = f"no_{i}_1"
                        insert_sql = """
                            INSERT INTO student (id, student_no, name, age, height, weight, score) 
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """
                        cursor.execute(insert_sql, (i, f"no_{i}", new_name, i, float(i), float(i), float(i)))
                        updated_count += 1
                        continue
                    
                    if len(update_list) >= batch_size or i == total_count:
                        batch_index += 1
                        if update_list:
                            update_sql = "UPDATE student SET name = %s WHERE id = %s"
                            cursor.executemany(update_sql, update_list)
                            connection.commit()
                            
                            updated_count += len(update_list)
                            update_list = []
                        
                        sys.stdout.write(
                            f"\r[第 {update_round}/{update_times} 轮更新] 批次: {batch_index} | 已更新: {updated_count} / {total_count} 条"
                        )
                        sys.stdout.flush()
                
                total_updated_all_rounds += updated_count
                print()  # 换行

            print(f"[所有更新完成] 共执行 {update_times} 轮更新，总计更新 {total_updated_all_rounds} 条次")

    except Exception as e:
        connection.rollback()
        print(f"\n[更新失败] 错误: {e}")
        raise e
    finally:
        connection.close()


def main():
    # 记录开始时间（微秒精度）
    start_time = time.perf_counter()
    start_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
    
    parser = argparse.ArgumentParser(
        description="DingoDB 压测工具（幂等性 INSERT + 多次 UPDATE name 字段）"
    )
    parser.add_argument("--host", required=True, help="数据库 IP 地址")
    parser.add_argument("--port", type=int, default=3307, help="数据库端口, 默认 3307")
    parser.add_argument("--user", required=True, help="数据库用户名")
    parser.add_argument("--password", default="123123", help="数据库密码, 默认 123123")
    parser.add_argument("--database", default="dingo", help="数据库名, 默认 dingo")
    parser.add_argument("--count", type=int, required=True, help="需要处理的数据行数（ID 范围 1 到 count）")
    parser.add_argument("--update-times", type=int, default=1, help="每条数据的更新次数，默认 1 次")
    parser.add_argument("--batch-size", type=int, default=10, help="每批次插入/更新的数据条数, 默认 10")

    args = parser.parse_args()

    db_config = {
        "host": args.host,
        "port": args.port,
        "user": args.user,
        "password": args.password,
        "database": args.database,
    }

    print("=" * 80)
    print(f"[任务启动时间] {start_timestamp}")
    print(f"[配置参数] count={args.count}, update_times={args.update_times}, batch_size={args.batch_size}")
    print("=" * 80)

    try:
        # 1. 创建表
        create_table(db_config)
        
        # 2. 初始插入/更新数据（幂等性操作）
        insert_or_update_initial_data(db_config, args.count, args.batch_size)
        
        # 3. 执行更新操作
        if args.update_times > 0:
            update_data(db_config, args.count, args.update_times, args.batch_size)
        
        # 计算总耗时
        end_time = time.perf_counter()
        end_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
        elapsed_seconds = end_time - start_time
        elapsed_microseconds = elapsed_seconds * 1_000_000
        
        print("\n" + "=" * 80)
        print(f"[任务完成时间] {end_timestamp}")
        print(f"[总耗时统计]")
        print(f"  - 秒: {elapsed_seconds:.6f} 秒")
        print(f"  - 毫秒: {elapsed_seconds * 1000:.3f} 毫秒")
        print(f"  - 微秒: {elapsed_microseconds:.0f} 微秒")
        print(f"[处理汇总] 共处理 {args.count} 条数据，每条数据更新 {args.update_times} 次")
        print("=" * 80)
        
    except Exception as e:
        end_time = time.perf_counter()
        elapsed_seconds = end_time - start_time
        print("\n" + "=" * 80)
        print(f"[任务失败] 错误: {e}")
        print(f"[失败前耗时] {elapsed_seconds:.6f} 秒 ({elapsed_seconds * 1000000:.0f} 微秒)")
        print("=" * 80)
        sys.exit(1)


if __name__ == "__main__":
    main()
