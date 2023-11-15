#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=hnsw --vector_index_type=hnsw --max_elements=2000000 --dimension=16 --efconstruction=40 --nlinks=32  --replica=1

