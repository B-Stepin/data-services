#!/bin/bash

function read_env(){
    export LOGNAME=projectofficer
    export HOME=/home/projectofficer
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

    script_bash_path=`readlink -f $0`
    script_dir=`dirname $script_bash_path`
    env_path=$script_dir"/env"
    if [ ! -f `readlink -f $env_path` ]
    then
        echo "env file does not exist. exit" 2>&1
        exit 1
    fi

    # read environmental variables from config.txt
    source `readlink -f $env_path`

    # subsistute env var from config.txt
    source /dev/stdin <<< `envsubst  < $script_dir/config.txt | sed '/^#/ d' | sed '/^$/d' |  sed 's:":'\'':g'|  sed 's:\s*=:=:g' | sed 's:=\s*:=":g' | sed 's:$:":g' | sed 's:^:export :g'`
}



function run_matlab(){
    matlab_script_name=aatams_sattag_dm_main.m
    matlab -nodisplay -r "run  ('"${script_dir}"/"${matlab_script_name}"');exit;"  2>&1 | tee  ${DIR}/${APP_NAME}.log ;
}


function run_rsync(){
    # remove empty directories see http://unix.stackexchange.com/questions/8430/how-to-remove-all-empty-directories-in-a-subtree
    if [ -d "$data_wip_path" ]; then
        while [ -n "$(find $data_wip_path -depth -type d -empty -print -exec rmdir {} +)" ]; do :; done
    fi

    rsync --dry-run --size-only --itemize-changes --delete-before  --stats -uhvrD  --progress ${data_wip_path}/NETCDF/  ${data_destination_path}/ ;
}


function main(){
    read_env

    APP_NAME=AATAMS_SATTAG_DM
    DIR=/tmp
    lockfile=${DIR}/${APP_NAME}.lock

    {
        if ! flock -n 9
        then
          echo "Program already running. Unable to lock $lockfile, exiting" 2>&1
          exit 1
        fi

        echo START ${APP_NAME}

        run_matlab
        run_rsync

    } 9>"$lockfile"
}

main