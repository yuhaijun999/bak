#!/bin/bash


cd ../build/bin/
./dingodb_client  --method=DocumentAdd --region_id=80089 --document_id=1 --document_text1="hello world" --document_text2="hello world" --timeout_ms=1000000 --log_each_request=false
./dingodb_client  --method=DocumentAdd --region_id=80089 --document_id=2 --document_text1="hello world" --document_text2="hello world" --timeout_ms=1000000 --log_each_request=false
./dingodb_client  --method=DocumentAdd --region_id=80089 --document_id=3 --document_text1="hello world" --document_text2="hello world" --timeout_ms=1000000 --log_each_request=false

