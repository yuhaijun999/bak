
# /// script
# dependencies = [
#     "pymysql",
# ]
# ///
# uv run manage_student.py   --host 172.30.14.14   --port 3307   --user root   --password 123123   --database dingo   --count 2147483647  --batch-size 7

import argparse
import sys
import pymysql


def create_table(db_config):
    """创建学生表"""
    # 将 text1 和 text2 修改为 VARCHAR(1048576) 满足 1M 大小需求
    sql = """
    CREATE TABLE IF NOT EXISTS student (
        id BIGINT,
        student_no VARCHAR(20) NOT NULL COMMENT '学号',
        name VARCHAR(50) NOT NULL COMMENT '学生姓名',
        age INT COMMENT '年龄',
        height DOUBLE COMMENT '身高(cm)',
        weight FLOAT(10,2) COMMENT '体重(kg)',
        score DOUBLE(10,2) COMMENT '考试成绩',
        text1 VARCHAR(1048576) COMMENT '大文本数据1',
        text2 VARCHAR(1048576) COMMENT '大文本数据2',
        PRIMARY KEY (id)
    ) ENGINE=TXN_LSM REPLICA=3 COMMENT='学生表';
    """

    cfg = db_config.copy()
    cfg["autocommit"] = True
    connection = pymysql.connect(**cfg)
    try:
        with connection.cursor() as cursor:
            cursor.execute(sql)
        print("[表结构] 表 student 校验成功（已创建或已存在，使用 VARCHAR(1M) 存储大文本）。")
    finally:
        connection.close()


def generate_padded_text(prefix, current_val, target_size_mb=1):
    """
    高效生成指定大小（MB）的填充文本
    格式例如: text1_123_abcdefg... 严格填满 1MB
    """
    base_str = f"{prefix}_{current_val}_"
    base_len = len(base_str.encode("utf-8"))

    # 计算目标字节数（1MB = 1024 * 1024 字节）
    target_bytes = target_size_mb * 1024 * 1024
    remaining_bytes = target_bytes - base_len

    if remaining_bytes <= 0:
        return base_str[:target_bytes]

    # 循环体填充明文内容 (26字节)
    filler = "abcdefghijklmnopqrstuvwxyz"
    filler_len = len(filler)

    repeat_count = remaining_bytes // filler_len
    remainder = remaining_bytes % filler_len

    # 使用 Python 的字符串乘法高速拼接
    padded_text = base_str + (filler * repeat_count) + filler[:remainder]
    return padded_text


def insert_stress_test(db_config, total_count, batch_size):
    """批量插入大文本数据压测函数"""
    # 关闭自动提交，由代码按 batch_size 块进行手动事务提交，最大化 LSM 写入性能
    db_config["autocommit"] = False
    connection = pymysql.connect(**db_config)

    try:
        with connection.cursor() as cursor:
            # 1. 获取当前最大 ID 基准
            cursor.execute("SELECT MAX(id) FROM student")
            result = cursor.fetchone()
            current_base = result[0] if (result and result[0] is not None) else 0

            print(f"\n[压测启动] 计划总插入: {total_count} 条，每批提交: {batch_size} 条")
            print(f"[数据体积] 每行包含 2MB 文本数据 (text1=1MB VARCHAR, text2=1MB VARCHAR)")
            print(f"[当前状态] 数据库最大 ID 基准: {current_base}\n")

            value_list = []
            inserted_count = 0
            batch_index = 0

            # 2. 循环构造并批量写入
            for i in range(1, total_count + 1):
                current_val = current_base + i

                # 构造基础字段
                row_id = int(current_val)
                student_no = f"no_{current_val}"
                name = f"name_{current_val}"
                age = int(current_val)
                height = float(current_val)
                weight = float(current_val)
                score = float(current_val)

                # 构造 1MB 的大文本字段 (明文格式)
                text1_content = generate_padded_text("text1", current_val, target_size_mb=1)
                text2_content = generate_padded_text("text2", current_val, target_size_mb=1)

                # 显式使用 PyMySQL 的 escape 确保大字符串中的特殊字符被安全转义，并自动带上单引号
                t1_escaped = connection.escape(text1_content)
                t2_escaped = connection.escape(text2_content)

                # 拼接单行 VALUES 格式
                value_str = f"({row_id}, '{student_no}', '{name}', {age}, {height}, {weight}, {score}, {t1_escaped}, {t2_escaped})"
                value_list.append(value_str)

                # 当达到指定的 batch_size 或者到了最后一条数据时，触发批量插入并提交
                if len(value_list) == batch_size or i == total_count:
                    batch_index += 1

                    # 拼接多行批量插入 SQL
                    batch_sql = f"INSERT INTO student (id, student_no, name, age, height, weight, score, text1, text2) VALUES {','.join(value_list)};"

                    # 执行并提交该批次
                    cursor.execute(batch_sql)
                    connection.commit()

                    inserted_count += len(value_list)

                    # 终端输出计数刷新
                    sys.stdout.write(
                        f"\r[进度反馈] 已成功提交批次: {batch_index} | 当前总计入库: {inserted_count} / {total_count} 条"
                    )
                    sys.stdout.flush()

                    # 清空当前批次缓存
                    value_list = []

            print(f"\n\n[压测完成] 成功追加并提交了 {inserted_count} 条大文本数据！当前最大 ID 已达: {current_base + inserted_count}")

    except Exception as e:
        connection.rollback()
        print(f"\n[压测中断] 遇到异常，当前批次已回滚。错误信息: {e}")
        raise e
    finally:
        connection.close()


def main():
    parser = argparse.ArgumentParser(
        description="Rocky 8 下使用 uv 运行的 DingoDB 大文本(VARCHAR 1M)压测工具"
    )
    parser.add_argument("--host", required=True, help="数据库 IP 地址 (Host)")
    parser.add_argument(
        "--port", type=int, default=3307, help="数据库端口 (Port), 默认 3307"
    )
    parser.add_argument("--user", required=True, help="数据库用户名 (User)")
    parser.add_argument(
        "--password", default="123123", help="数据库密码 (Password), 默认 123123"
    )
    parser.add_argument(
        "--database", default="dingo", help="数据库名 (Database), 默认 dingo"
    )
    parser.add_argument(
        "--count", type=int, required=True, help="需要创建/插入的总行数 (Total lines)"
    )
    parser.add_argument(
        "--batch-size", type=int, default=10, help="每批次插入并提交的数据条数, 默认 10"
    )

    args = parser.parse_args()

    db_config = {
        "host": args.host,
        "port": args.port,
        "user": args.user,
        "password": args.password,
        "database": args.database,
    }

    create_table(db_config)
    insert_stress_test(db_config, args.count, args.batch_size)


if __name__ == "__main__":
    main()
