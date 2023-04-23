#!/bin/bash


FLAGS_role=store
#echo "role: ${FLAGS_role}"

user=`whoami`
process_no=`ps -fu ${user} | grep dingodb_server | grep ${FLAGS_role} | grep -v grep | awk '{print $2}' | xargs`

if [ "$process_no" != "" ]; then
    echo "role : ${FLAGS_role} pid to show: ${process_no}"
    ps -elf | grep  $process_no | grep -v grep
    netstat -nap | grep $process_no
else
    echo "not exist ${FLAGS_role} process"
fi

