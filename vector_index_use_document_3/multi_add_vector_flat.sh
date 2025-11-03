#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatchUseDocument --region_id=80001 --count=10000 --start_id=10000 --without_scalar=false --timeout_ms=1000000 --log_each_request=false
./dingodb_client  --method=VectorAddBatchUseDocument --region_id=80001 --count=10000 --start_id=20000 --without_scalar=false --timeout_ms=1000000 --log_each_request=false
./dingodb_client  --method=VectorAddBatchUseDocument --region_id=80001 --count=10000 --start_id=30000 --without_scalar=false --timeout_ms=1000000 --log_each_request=false
