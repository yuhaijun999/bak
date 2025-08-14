#!/bin/bash



function remove_coordinator(){
    local role_dir=$1
    echo "role: ${role_dir}"

    if [ -d ${role_dir}/data ] ; then
        rm ${role_dir}/data/* -rf
    fi

    tree ${role_dir}
}

remove_coordinator coordinator1
