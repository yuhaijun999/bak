#!/bin/bash


cd ../build/bin/
./dingodb_client --method=TxnScan --start_key=77000000000000ea62   --key_is_hex=true  --end_key=77000000000000ea63  --limit=10  --key_only=false --is_reverse=false --start_ts=1705563698882 --region_id=80001 --timeout_ms=1000000
