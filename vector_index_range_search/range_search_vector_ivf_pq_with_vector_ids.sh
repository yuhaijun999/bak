#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorRangeSearch --region_id=80004 --dimension=16 --radius=500 --vector_id=0  --without_vector=false --without_scalar=false --without_table=false  --with_vector_ids=true  --timeout_ms=1000000 

