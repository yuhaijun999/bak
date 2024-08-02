#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatch --region_id=80001 --dimension=1024 --count=10  --step_count=1   --start_id=1 --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./flat-10000.txt"

