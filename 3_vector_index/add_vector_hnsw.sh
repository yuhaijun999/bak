#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatch --region_id=80003 --dimension=1024 --count=1000000  --step_count=1000   --start_id=1 --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./hnsw-1000000.txt"
