#!/bin/bash

role=index
FLAGS_role="\-role=$role"
#echo "role: ${FLAGS_role}"

user=`whoami`
process_nos=`ps -fu ${user} | grep dingodb_server | grep "${FLAGS_role}" | grep -v grep | awk '{print $2}' | xargs`

echo "...................................................................................................................."
echo $role "pids:" ${process_nos}

if [ "$process_nos" != "" ]; then
    for process_no in ${process_nos}
    do
        echo "role : ${role} pid to show: ${process_no}"
        ps -elf | grep  $process_no | grep -v grep
        netstat -nap | grep $process_no
    done
else
    echo "not exist ${role} process"
fi

