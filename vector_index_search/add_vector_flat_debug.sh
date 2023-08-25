#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatchDebug --region_id=80001 --dimension=1024 --count=1000000  --step_count=1000   --start_id=1 --with_scalar=true --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./flat-1000000.txt"

