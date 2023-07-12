#!/bin/bash

cd store1
./bin/dingodb_server --role store --conf ./conf/store.yaml --coor_url=file://./conf/coor_list &
cd ..

