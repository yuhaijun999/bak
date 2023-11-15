#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorRangeSearchDebug --region_id=80003 --dimension=16 --radius=11900 --vector_id=0  --without_vector=false --without_scalar=false --without_table=false  --with_scalar_pre_filter=true  --timeout_ms=1000000 

