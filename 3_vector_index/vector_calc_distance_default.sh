#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorCalcDistance --region_id=80001 --dimension=16  --timeout_ms=1000000 

