#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorBatchSearch --region_id=80001 --dimension=8 --topn=10 --batch_count=3 --vector_id=0  --without_vector=false --with_scalar=true --with_table=true  --with_vector_ids=true  --timeout_ms=1000000 

