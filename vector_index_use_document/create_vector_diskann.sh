#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateVectorIndexUseDocument --name=diskann --vector_index_type=diskann --max_degree=64 --search_list_size=100 --dimension=8  --replica=1 --with_scalar_schema=true --enable_scalar_speed_up_with_document=true
