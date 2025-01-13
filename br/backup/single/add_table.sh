#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=KvBatchPut --region_id=80045 --prefix=77000000000000eab6 --count=1000 --timeout_ms=1000000 --log_each_request=false

