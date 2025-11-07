#!/bin/bash


cd ../build/bin/
./dingodb_client --method=MergeRegion --target_id=80001  --source_id=80002   --timeout_ms=1000000 --log_each_request=false 
