#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorRangeSearchDebug --region_id=80001 --dimension=16 --radius=100 --vector_id=0  --without_vector=false --without_scalar=false --without_table=false  --with_scalar_post_filter=true  --timeout_ms=1000000 

