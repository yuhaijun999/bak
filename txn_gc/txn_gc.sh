#!/bin/bash


cd ../build/bin/

if [ $# != 1 ] ; then
echo "USAGE: Param1 safe_point_ts"
exit 1;
fi
echo safe_point_ts : $1

./dingodb_client  --method=TxnGC --region_id=80001 --safe_point_ts=$1  --timeout_ms=1000000 


