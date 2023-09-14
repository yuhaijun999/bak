#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorSearchDebug --region_id=80001 --dimension=1024 --topn=10 --vector_id=0 --batch_count=1 --vector_ids_count=100000 --without_vector=true --without_scalar=true --without_table=true  --with_vector_ids=true   --timeout_ms=1000000 --print_vector_search_delay=true

