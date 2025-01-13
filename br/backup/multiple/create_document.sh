#!/bin/bash


cd ../build/bin/
./dingodb_client --method=CreateDocumentIndex --name=document  --replica=3
