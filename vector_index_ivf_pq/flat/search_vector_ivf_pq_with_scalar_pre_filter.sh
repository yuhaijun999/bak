#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearch --region_id=80004 --dimension=16 --topn=10 --vector_id=0  --without_vector=false --without_scalar=false --without_table=false  --with_scalar_pre_filter=true  --timeout_ms=1000000 

