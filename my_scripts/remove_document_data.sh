#!/bin/bash


function remove_store(){
    local role_dir=$1
    echo "role: ${role_dir}"

    if [ -d ${role_dir}/data ] ; then
        rm ${role_dir}/data/* -rf
    fi

    tree ${role_dir}

}


remove_store document1
