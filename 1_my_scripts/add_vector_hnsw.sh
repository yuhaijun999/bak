#!/bin/bash


cd ../build/bin/
./dingodb_client_store  --method=VectorAddBatch --region_id=80003 --dimension=1024 --count=1000000  --step_count=2048  --vector_enable_scalar=false --start_id=0 --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./hnsw-1000000.txt"

