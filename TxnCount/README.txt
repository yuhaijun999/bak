
store 节点 查看 txn region 数据条数. 默认对整个region 进行计数.
内部使用 TxnScan rpc 接口

1.dingodb_client
./dingodb_client --method=TxnCount  --region_id=80001
./dingodb_client --method=TxnCount  --region_id=80001 --rc=true
./dingodb_client --method=TxnCount  --region_id=80001 --rc=false
./dingodb_client --method=TxnCount  --region_id=80002 --rc=true --start_key=xBENCH3d67bed5-41d1-1eaa-f6d0-b8ddb097572f --end_key=xBENCH3d67bed5-41d1-1eaa-f6d0-b8ddb097572g --key_is_hex=true



2. dingodb_cli
./dingodb_cli TxnCount --id=80001
./dingodb_cli TxnCount --id=80001 --rc=true
./dingodb_cli TxnCount --id=80001 --rc=true  --start_key=xBENCH3d67bed5-41d1-1eaa-f6d0-b8ddb097572f --end_key=xBENCH3d67bed5-41d1-1eaa-f6d0-b8ddb097572g  --is_hex=true




