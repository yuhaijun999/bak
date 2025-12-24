#!/bin/bash


cd ../build/bin/
./dingodb_cli TransferLeaderRegion --region_id=80001 --store_id=30001 
./dingodb_cli TransferLeaderRegion --region_id=80001 --store_id=30002 
./dingodb_cli TransferLeaderRegion --region_id=80001 --store_id=30003 
