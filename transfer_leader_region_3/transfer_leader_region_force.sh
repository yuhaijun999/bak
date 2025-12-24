#!/bin/bash


cd ../build/bin/
./dingodb_cli TransferLeaderRegion --region_id=80001 --store_id=30001 --force=true
./dingodb_cli TransferLeaderRegion --region_id=80001 --store_id=30002 --force=true
./dingodb_cli TransferLeaderRegion --region_id=80001 --store_id=30003 --force=true
