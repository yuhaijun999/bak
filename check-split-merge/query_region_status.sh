#!/bin/bash

cd ../build/bin/
./dingodb_cli QueryRegionStatus --store_addrs=172.30.14.11:30001   --region_ids=80001
./dingodb_cli QueryRegionStatus --store_addrs=172.30.14.11:30002   --region_ids=80001
./dingodb_cli QueryRegionStatus --store_addrs=172.30.14.11:30003   --region_ids=80001
