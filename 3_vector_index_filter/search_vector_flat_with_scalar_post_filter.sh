#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearch --region_id=80001 --dimension=8 --topn=10 --vector_id=0  --without_vector=false --with_scalar=true --with_table=true  --with_scalar_post_filter=true  --timeout_ms=1000000 

