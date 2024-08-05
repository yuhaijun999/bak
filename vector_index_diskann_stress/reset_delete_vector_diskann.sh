#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorReset --region_id=80001 --delete_data_file=true  --timeout_ms=1000000

