#!/bin/bash


FLAGS_role=store
echo "role: ${FLAGS_role}"

user=`whoami`
process_no=`ps -fu ${user} | grep dingodb_server | grep ${FLAGS_role} | grep -v grep | awk '{print $2}' | xargs`

if [ "$process_no" != "" ]; then
    echo "pid to kill: ${process_no}"
    kill -9 $process_no
else
    echo "not exist ${FLAGS_role} process"
fi

