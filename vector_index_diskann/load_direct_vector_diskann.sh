#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorLoad --region_id=80001 --direct_load_without_build=true --num_nodes_to_cache=2 --warmup=true   --timeout_ms=1000000

