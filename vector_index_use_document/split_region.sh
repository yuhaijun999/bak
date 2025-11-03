#!/bin/bash


cd ../build/bin/
#./dingodb_client --method=SplitRegion --split_from_id=80001 --split_to_id=80002  --store_create_region=true --vector_id=6   --timeout_ms=1000000 --log_each_request=false 
./dingodb_client --method=SplitRegion --split_from_id=80001  --store_create_region=false --vector_id=6   --timeout_ms=1000000 --log_each_request=false 
