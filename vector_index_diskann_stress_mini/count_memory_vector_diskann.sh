#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorCountMemory --region_id=80001  --timeout_ms=1000000

