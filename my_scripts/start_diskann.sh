#!/bin/bash

export TCMALLOC_SAMPLE_PARAMETER=524288
echo "export TCMALLOC_SAMPLE_PARAMETER=524288, to enable heap profiler"

ulimit -n 1048576
ulimit -u 4194304
ulimit -c unlimited

cd diskann1
mkdir -p ./log
./bin/dingodb_server -role=diskann  > ./log/out 2>&1 &
cd ..

