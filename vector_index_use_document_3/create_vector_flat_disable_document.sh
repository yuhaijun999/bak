#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateVectorIndexUseDocument --name=flat --vector_index_type=flat --dimension=8  --replica=3 --with_scalar_schema=true --enable_scalar_speed_up_with_document=false
