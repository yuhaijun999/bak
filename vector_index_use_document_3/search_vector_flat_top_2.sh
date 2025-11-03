#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearchUseDocument --region_id=80002 --topn=10 --with_scalar_pre_filter=true  --without_vector=true --without_scalar=true --without_table=true    --timeout_ms=1000000 --print_vector_search_delay=true

