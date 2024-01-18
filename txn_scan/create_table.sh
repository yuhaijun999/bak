#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateTable --name=test1 --engine=rocksdb  --replica=1 --timeout_ms=1000000
