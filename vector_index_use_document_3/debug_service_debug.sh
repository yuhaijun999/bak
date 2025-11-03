#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=DebugServiceDebug --region_id=80001  --debug_service_debug_type=INDEX_VECTOR_INDEX_METRICS --timeout_ms=1000000 --log_each_request=false
