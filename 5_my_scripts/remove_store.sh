#!/bin/bash


function remove_store(){
    local role_dir=$1
    echo "role: ${role_dir}"

    if [ -d ${role_dir}/log ] ; then
        rm ${role_dir}/log/* -rf
    fi


    tree ${role_dir}

}


remove_store store1
remove_store store2
remove_store store3
remove_store store4
remove_store store5
