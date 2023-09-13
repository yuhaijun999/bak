#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDelete --region_id=80002 --count=10  --start_id=1000000 --timeout_ms=1000000 

