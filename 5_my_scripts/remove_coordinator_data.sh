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
remove_coordinator coordinator2
remove_coordinator coordinator3
remove_coordinator coordinator4
remove_coordinator coordinator5
