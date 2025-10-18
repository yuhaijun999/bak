#!/bin/bash


function clean_store(){
    local role_dir=$1
    echo "role: ${role_dir}"

    if [ -d ${role_dir}/data ]; then
        rm ${role_dir}/data/* -rf
    else
        mkdir -p ${role_dir}/data
    fi


    if [ -d ${role_dir}/log ] ; then
        rm ${role_dir}/log/* -rf
    else
        mkdir -p ${role_dir}/log
    fi


    tree ${role_dir}

}


clean_store document1
clean_store document2
clean_store document3
clean_store document4
clean_store document5
