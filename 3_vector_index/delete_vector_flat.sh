#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDelete --region_id=80001 --count=10  --start_id=0 --timeout_ms=1000000 

