#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDump --region_id=80001 --dump_all=false  --timeout_ms=1000000

