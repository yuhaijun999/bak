#!/bin/bash


export TCMALLOC_SAMPLE_PARAMETER=524288
echo "export TCMALLOC_SAMPLE_PARAMETER=524288, to enable heap profiler"

ulimit -n 1048576
ulimit -u 4194304
ulimit -c unlimited

cd index1
./bin/dingodb_server -role=index &
cd ..

cd index2
./bin/dingodb_server -role=index &
cd ..

cd index3
./bin/dingodb_server -role=index &
cd ..
