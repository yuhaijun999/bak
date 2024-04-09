#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDelete --region_id=80001 --count=1  --start_id=1 --timeout_ms=1000000 

