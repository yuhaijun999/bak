#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorAdd --region_id=80001 --dimension=8 --count=10  --step_count=10   --start_id=1 --without_scalar=false --scalar_filter_key=enable_scalar_schema --scalar_filter_key2=enable_scalar_schema  --scalar_filter_value=enable_scalar_schema --scalar_filter_value2=enable_scalar_schema --timeout_ms=1000000 --log_each_request=false --vector_index_add_cost_file="./flat-10.txt"

