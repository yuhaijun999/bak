#!/bin/bash


function clean_store(){
    local role_dir=$1
    echo "role: ${role_dir}"

    if [ -d ${role_dir}/data ]; then
        if [ -d  ${role_dir}/data/index ]; then
            if [ -d ${role_dir}/data/index/checkpoint ]; then
                rm ${role_dir}/data/index/checkpoint/* -rf
            else
                mkdir -p ${role_dir}/data/index/checkpoint
            fi

            if [ -d ${role_dir}/data/index/db ]; then
                rm ${role_dir}/data/index/db/* -rf
            else
                mkdir -p ${role_dir}/data/index/db
            fi

            if [ -d ${role_dir}/data/index/raft ]; then
                rm ${role_dir}/data/index/raft/* -rf
            else
                mkdir -p ${role_dir}/data/index/raft
            fi

            if [ -d ${role_dir}/data/index/log ]; then
                rm ${role_dir}/data/index/log/* -rf
            else
                mkdir -p ${role_dir}/data/index/log
            fi

            if [ -d ${role_dir}/data/index/idx ]; then
                rm ${role_dir}/data/index/idx/* -rf
            else
                mkdir -p ${role_dir}/data/index/idx
            fi
        else
            mkdir -p ${role_dir}/data/index
            mkdir -p ${role_dir}/data/index/checkpoint
            mkdir -p ${role_dir}/data/index/db
            mkdir -p ${role_dir}/data/index/log
            mkdir -p ${role_dir}/data/index/raft
            mkdir -p ${role_dir}/data/index/idx
        fi

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
        mkdir -p ${role_dir}/data/index
        mkdir -p ${role_dir}/data/index/checkpoint
        mkdir -p ${role_dir}/data/index/db
        mkdir -p ${role_dir}/data/index/raft
        mkdir -p ${role_dir}/data/index/idx
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

}


clean_store index1
