#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorImport --region_id=80001 --dimension=1024 --import_for_add=false --count=10  --step_count=10   --start_id=1 --timeout_ms=1000000

