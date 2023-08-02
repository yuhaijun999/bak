#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=faiss --metric_type=l2 --left_vector_size=2 --right_vector_size=3 --is_return_normlize=true  --timeout_ms=1000000 

