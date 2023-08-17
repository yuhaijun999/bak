#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearchDebug --region_id=80003 --dimension=1024 --topn=10 --batch_count=1 --vector_id=0  --without_vector=true --with_scalar=false --with_table=false  --with_scalar_pre_filter=true --key=tag6 --value=tag6  --timeout_ms=1000000 --print_vector_search_delay=true

