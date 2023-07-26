#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateIndex --name=flat --vector_index_type=flat --dimension=1024  --replica=1
