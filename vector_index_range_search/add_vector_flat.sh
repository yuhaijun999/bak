#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAddBatch --region_id=80001 --dimension=16 --count=100000  --step_count=1000   --start_id=1 --without_scalar=false --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./ivf_pq-1000000.txt"

