#!/bin/bash


cd ../build/bin/
./dingodb_client --method=KvScanBeginV2 --scan_id=1 --region_id=80001 --timeout_ms=1000000
