#!/bin/bash

cd coordinator1
./bin/dingodb_server --role coordinator --conf ./conf/coordinator.yaml --coor_url=file://./conf/coor_list  &
