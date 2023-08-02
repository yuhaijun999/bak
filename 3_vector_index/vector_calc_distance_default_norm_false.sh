#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16 --is_return_normlize=false  --timeout_ms=1000000 

