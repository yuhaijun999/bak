#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=0 --alg_type=faiss --metric_type=l2 --left_vector_size=2 --right_vector_size=3 --is_return_normlize=true  --timeout_ms=1000000 

#alg_type invalid
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=myfaiss --metric_type=l2 --left_vector_size=2 --right_vector_size=3 --is_return_normlize=true  --timeout_ms=1000000 

# metric_type invalid
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=faiss --metric_type=myl2 --left_vector_size=2 --right_vector_size=3 --is_return_normlize=true  --timeout_ms=1000000 

#left_vector_size = 0
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=faiss --metric_type=l2 --left_vector_size=0 --right_vector_size=3 --is_return_normlize=true  --timeout_ms=1000000 

#right_vector_size = 0
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=faiss --metric_type=l2 --left_vector_size=2 --right_vector_size=0 --is_return_normlize=true  --timeout_ms=1000000 

# ok 
#./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=faiss --metric_type=l2 --left_vector_size=1 --right_vector_size=3 --is_return_normlize=true  --timeout_ms=1000000 
#./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --alg_type=faiss --metric_type=l2 --left_vector_size=2 --right_vector_size=1 --is_return_normlize=true  --timeout_ms=1000000 

