#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatch --region_id=80002 --dimension=1024 --count=1000  --step_count=1000   --start_id=1000001 --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./flat-1000000-2.txt"

