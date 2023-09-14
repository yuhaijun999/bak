#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=hnsw --vector_index_type=hnsw --max_elements=2000000 --dimension=1024 --efconstruction=40 --nlinks=32  --replica=3

