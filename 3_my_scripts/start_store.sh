#!/bin/bash

cd store1
./bin/dingodb_server -role=store  &
cd ..

cd store2
./bin/dingodb_server -role=store  &
cd ..

cd store3
./bin/dingodb_server -role=store  &
cd ..
