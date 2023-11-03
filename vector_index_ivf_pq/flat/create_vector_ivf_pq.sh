#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=ivf_pq --vector_index_type=ivf_pq --dimension=16 --ncentroids=6 -nsubvector=8 -nbits_per_idx=4    --replica=1
