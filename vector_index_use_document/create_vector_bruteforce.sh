#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateVectorIndexUseDocument --name=bruteforce --vector_index_type=bruteforce --dimension=8  --replica=1 --with_scalar_schema=true --enable_scalar_speed_up_with_document=true
