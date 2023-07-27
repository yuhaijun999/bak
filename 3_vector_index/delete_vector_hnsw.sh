#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDelete --region_id=80003 --count=10  --start_id=1 --timeout_ms=1000000 

