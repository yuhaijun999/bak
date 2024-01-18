#!/bin/bash


cd ../build/bin/
./dingodb_client --method=KvBatchPut --prefix="" --region_id=80001 --timeout_ms=1000000
