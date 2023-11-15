#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorRangeSearchDebug --region_id=80001 --dimension=16 --radius=300 --vector_id=0  --without_vector=false --without_scalar=false --without_table=false  --with_vector_ids=true  --timeout_ms=1000000 

