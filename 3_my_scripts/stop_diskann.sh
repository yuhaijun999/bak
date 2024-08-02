#!/bin/bash

role=diskann
FLAGS_role="\-role=$role"
#echo "role: ${FLAGS_role}"

user=`whoami`
process_nos=`ps -fu ${user} | grep diskann_server | grep "${FLAGS_role}" | grep -v grep | awk '{print $2}' | xargs`

echo "...................................................................................................................."
echo $role "pids:" ${process_nos}

if [ "$process_nos" != "" ]; then
    for process_no in ${process_nos}
    do
    	echo "pid to kill: ${process_no}"
    	kill -9 $process_no
    done
else
    echo "not exist ${role} process"
fi

