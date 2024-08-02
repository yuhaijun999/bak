#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorReset --region_id=80001 --delete_data_file=false  --timeout_ms=1000000

