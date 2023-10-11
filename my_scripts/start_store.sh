#!/bin/bash

export TCMALLOC_SAMPLE_PARAMETER=524288
echo "export TCMALLOC_SAMPLE_PARAMETER=524288, to enable heap profiler"

ulimit -n 40960
ulimit -u 40960


cd store1
./bin/dingodb_server -role=store &
cd ..

