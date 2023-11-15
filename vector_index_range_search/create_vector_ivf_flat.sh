#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=ivf_flat --vector_index_type=ivf_flat --dimension=16 --ncentroids=100  --replica=1
