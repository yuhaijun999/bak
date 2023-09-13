#!/bin/bash

cd index1
./bin/dingodb_server --role index --conf ./conf/index.yaml --coor_url=file://./conf/coor_list &
cd ..

cd index2
./bin/dingodb_server --role index --conf ./conf/index.yaml --coor_url=file://./conf/coor_list &
cd ..

cd index3
./bin/dingodb_server --role index --conf ./conf/index.yaml --coor_url=file://./conf/coor_list &
cd ..
