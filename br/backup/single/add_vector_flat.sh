#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatch --region_id=80046 --dimension=8 --count=10000  --step_count=1000 --start_id=1 --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./flat-10000.txt"

