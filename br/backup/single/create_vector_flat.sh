#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=flat --vector_index_type=flat --dimension=8  --replica=1
