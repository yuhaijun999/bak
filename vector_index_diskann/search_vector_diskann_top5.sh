#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearch --region_id=80001 --dimension=1024 --topn=5 --vector_id=10000 --batch_count=1 --vector_ids_count=3 --without_vector=true --without_scalar=true --without_table=true    --timeout_ms=1000000 --print_vector_search_delay=true

