#!/bin/bash


cd ../build/bin/
./dingodb_cli ModifyRegionMeta --store_addrs 172.30.14.11:30001 --region_id 80001 --state 1
./dingodb_cli ModifyRegionMeta --store_addrs 172.30.14.11:30002 --region_id 80001 --state 1
./dingodb_cli ModifyRegionMeta --store_addrs 172.30.14.11:30003 --region_id 80001 --state 1
