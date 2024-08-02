#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorImport --region_id=80002 --dimension=1024 --import_for_add=true --count=100  --step_count=10   --start_id=10000 --timeout_ms=1000000

