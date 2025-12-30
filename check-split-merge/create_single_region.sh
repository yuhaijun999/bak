#!/bin/bash

# 单个region
./dingodb_bench --benchmark=filltxnseq --batch_threads=1 --batch_threads_sleep_ms=10000 --coordinator_interaction_delay_ms=1000 --req_num=10000000000000 --is_single_region_txn=true --batch_size=1 --key_size=256 --value_size=1024 --concurrency=1 --region_num=1 --enable_trace_rpc_performance=false --is_clean_region=false --replica=1
