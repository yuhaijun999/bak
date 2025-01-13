#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateTable --name=table  --replica=3
