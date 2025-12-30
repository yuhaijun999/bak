#!/bin/bash
#./dingodb_client --method=GetStoreMap -use-filter-store-type=true -filter-store-type=0 -use_filter_store_type=true | grep store_id= | sed 's/.*store_id=\([0-9]*\).*host: "\([^"]*\)".*port: \([0-9]*\).*/\1 \2:\3/' > store_map.txt
./dingodb_client --method=GetStoreMap | grep store_id= | sed 's/.*store_id=\([0-9]*\).*host: "\([^"]*\)".*port: \([0-9]*\).*/\1 \2:\3/' > store_map.txt
