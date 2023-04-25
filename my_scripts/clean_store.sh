#!/bin/bash


role_dir=store1
echo "role: ${role_dir}"

if [ -d ${role_dir}/data ]; then
    if [ -d  ${role_dir}/data/store ]; then
        if [ -d ${role_dir}/data/store/db ]; then
            rm ${role_dir}/data/store/db/* -rf
        else
            mkdir -p ${role_dir}/data/store/db
        fi

        if [ -d ${role_dir}/data/store/raft ]; then
            rm ${role_dir}/data/store/raft/* -rf
        else
            mkdir -p ${role_dir}/data/store/raft
        fi
    else
        mkdir -p ${role_dir}/data/store
        mkdir -p ${role_dir}/data/store/db
        mkdir -p ${role_dir}/data/store/raft
    fi
else
    mkdir -p ${role_dir}/data
    mkdir -p ${role_dir}/data/store
    mkdir -p ${role_dir}/data/store/db
    mkdir -p ${role_dir}/data/store/raft
fi


if [ -d ${role_dir}/log ] ; then
    rm ${role_dir}/log/* -rf
else
    mkdir -p ${role_dir}/log
fi


tree ${role_dir}
