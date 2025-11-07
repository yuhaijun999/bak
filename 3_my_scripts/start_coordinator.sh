#!/bin/bash

export TCMALLOC_SAMPLE_PARAMETER=524288
echo "export TCMALLOC_SAMPLE_PARAMETER=524288, to enable heap profiler"

ulimit -n 1048576
ulimit -u 4194304
ulimit -c unlimited

cd coordinator1
./bin/dingodb_server -role=coordinator  &
cd ..

cd coordinator2
./bin/dingodb_server -role=coordinator  &
cd ..

cd coordinator3
./bin/dingodb_server -role=coordinator  &
cd ..
