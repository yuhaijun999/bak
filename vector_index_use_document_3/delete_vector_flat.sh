#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDeleteUseDocument --region_id=80001 --count=10 --start_id=1 --timeout_ms=1000000 --log_each_request=false
