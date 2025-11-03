#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=VectorDisplayDocumentDetails --region_id=80001 --timeout_ms=1000000 --log_each_request=false
