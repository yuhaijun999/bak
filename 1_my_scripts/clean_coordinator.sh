#!/bin/bash



function clean_coordinator(){
    local role_dir=$1
    echo "role: ${role_dir}"

    if [ -d ${role_dir}/data ]; then
        if [ -d  ${role_dir}/data/coordinator ]; then
            if [ -d ${role_dir}/data/coordinator/checkpoint ]; then
                rm ${role_dir}/data/coordinator/checkpoint/* -rf
            else
                mkdir -p ${role_dir}/data/coordinator/checkpoint
            fi

            if [ -d ${role_dir}/data/coordinator/db ]; then
                rm ${role_dir}/data/coordinator/db/* -rf
            else
                mkdir -p ${role_dir}/data/coordinator/db
            fi

            if [ -d ${role_dir}/data/coordinator/idx ]; then
                rm ${role_dir}/data/coordinator/idx/* -rf
            else
                mkdir -p ${role_dir}/data/coordinator/idx
            fi


            if [ -d ${role_dir}/data/coordinator/log ]; then
                rm ${role_dir}/data/coordinator/log/* -rf
            else
                mkdir -p ${role_dir}/data/coordinator/log
            fi

            if [ -d ${role_dir}/data/coordinator/raft ]; then
                rm ${role_dir}/data/coordinator/raft/* -rf
            else
                mkdir -p ${role_dir}/data/coordinator/raft
            fi
        else
            mkdir -p ${role_dir}/data/coordinator
            mkdir -p ${role_dir}/data/coordinator/checkpoint
            mkdir -p ${role_dir}/data/coordinator/db
            mkdir -p ${role_dir}/data/coordinator/idx
            mkdir -p ${role_dir}/data/coordinator/log
            mkdir -p ${role_dir}/data/coordinator/raft
        fi
    else
        mkdir -p ${role_dir}/data
        mkdir -p ${role_dir}/data/coordinator
        mkdir -p ${role_dir}/data/coordinator/checkpoint
        mkdir -p ${role_dir}/data/coordinator/db
        mkdir -p ${role_dir}/data/coordinator/idx
        mkdir -p ${role_dir}/data/coordinator/log
        mkdir -p ${role_dir}/data/coordinator/raft
    fi


    if [ -d ${role_dir}/log ] ; then
        rm ${role_dir}/log/* -rf 
    else
        mkdir -p ${role_dir}/log
    fi


    tree ${role_dir}
}

clean_coordinator coordinator1
