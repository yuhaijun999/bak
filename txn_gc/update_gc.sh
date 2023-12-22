#!/bin/bash


cd ../build/bin/

if [ $# != 2 ] ; then
echo "USAGE: Param1 : gc_flag (start or stop) Param2 :  safe_point"
exit 1;
fi
echo gc_flag : $1  safe_point : $2

./dingodb_client  --method=UpdateGCSafePoint --region_id=80001 --gc_flag=$1  --safe_point=$2  --timeout_ms=1000000 


