#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearchDebug --region_id=80001 --dimension=1024 --topn=10 --batch_count=1 --vector_id=0  --without_vector=true --without_scalar=true --without_table=true  --with_scalar_post_filter=true --key=tag5 --value=tag5  --timeout_ms=1000000 --print_vector_search_delay=true

