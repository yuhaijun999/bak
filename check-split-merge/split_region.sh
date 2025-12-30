#!/bin/bash

cd ../build/bin/
./dingodb_cli SplitRegion --split_from_id=80001 --store_create_region=false
