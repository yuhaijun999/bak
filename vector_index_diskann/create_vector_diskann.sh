#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=diskann --vector_index_type=diskann --max_degree=64 --dimension=1024 --search_list_size=100  --replica=1

