#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorRangeSearchDebug --region_id=80004 --dimension=16 --radius=301  --vector_id=0 --batch_count=1 --vector_ids_count=10 --without_vector=true --without_scalar=true --without_table=true    --timeout_ms=1000000 --print_vector_search_delay=true

