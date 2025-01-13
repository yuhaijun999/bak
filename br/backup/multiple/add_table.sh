#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=KvBatchPut --region_id=80087 --prefix=77000000000000eb0a --count=1000 --timeout_ms=1000000 --log_each_request=false

