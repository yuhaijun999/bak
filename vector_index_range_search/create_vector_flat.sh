#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=flat --vector_index_type=flat --dimension=16  --replica=1
