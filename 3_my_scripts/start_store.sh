#!/bin/bash

cd store1
./bin/dingodb_server --role store --conf ./conf/store.yaml --coor_url=file://./conf/coor_list &
cd ..

cd store2
./bin/dingodb_server --role store --conf ./conf/store.yaml --coor_url=file://./conf/coor_list &
cd ..

cd store3
./bin/dingodb_server --role store --conf ./conf/store.yaml --coor_url=file://./conf/coor_list &
cd ..
