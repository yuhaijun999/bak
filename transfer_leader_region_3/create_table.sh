#!/bin/bash


cd ../build/bin/
./dingodb_cli CreateTable --name=my_table --schema_id=1 --part_count=1   --replica=3
