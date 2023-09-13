#!/bin/bash

cd index1
./bin/dingodb_server -role=index &
cd ..

cd index2
./bin/dingodb_server -role=index &
cd ..

cd index3
./bin/dingodb_server -role=index &
cd ..
