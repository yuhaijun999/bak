#!/bin/bash

cd coordinator1
./bin/dingodb_server -role=coordinator  &
cd ..

cd coordinator2
./bin/dingodb_server -role=coordinator  &
cd ..

cd coordinator3
./bin/dingodb_server -role=coordinator  &
cd ..
