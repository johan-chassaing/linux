#!/bin/bash
##########################################
#
#  Author:  Johan Chassaing
#  Date:    2017/09/19
#  Licence: GPL
#
#################
#
#  Dependencies:
#
#################
#
#  Script to send files to an SFTP server
#  User uses public key
#  copy all CSV files to Archives
#  process done file by file:
#      compress CSV
#      generate compressed CSV hash
#      send compressed CSV
#      send compressed CSV hash
#      delete compressed CSV and compressed CSV hash
#      move file to Archives
#
##########################################

##########################################
#
#               Variables
#
##########################################

prog_name="transfert-sftp"
datetime="$(date +%Y%m%d-%H%M%S%2N)"

# Files pattern:
file_pattern="*.CSV"

# Destination SFTP server
dst_server="127.0.0.1"
dst_port="22"
dst_account="testsftp"
dst_path="upload"
ssh_timeout=30

# Local paths
prog_path="./"
work_path="${prog_path}/"
archives_path="${prog_path}/ARCHIVES"
log_path="${prog_path}/LOGS"

# Logs
log="${log_path}/${prog_name}-${datetime}.log"
log_max_day=1

compress_prog="$(which zip)"
compress_ext="zip"

hash_prog="$(which sha1sum)"
hash_ext="sha1"

set -o pipefail

##########################################
#
#               Functions
#
##########################################

##### sftp_cmd
#
# send a file to a sftp server
# usage: sftp-cmd method folder file

function sftp_cmd (){ 

    echo_log "$1 file $2/$3 to/from server ${dst_account}@${dst_server}:${dst_port}"

    sftp -o PreferredAuthentications=publickey -o ConnectTimeout=$ssh_timeout -b - \
         -P ${dst_port} ${dst_account}@${dst_server} 2>&1 <<< "$1 $3 $2/$3" | tee -a "$log" 

    RC="$?"
    ## check SFTP return code
    if [[ "$RC" -ne "0" ]]; then
        echo_log "Error with the SFTP connection on ${dst_account}@${dst_server}:${dst_port}"
        echo_log "Error sftp return code = $RC"
        error_code=$RC
    fi
    return $RC
}

##### exit_on_error
#
# print a message on both stdout and log file and exit
# usage: exit_on_error returnCode message

function exit_on_error () {
    echo "$2" | tee -a "$log"
    exit "$1"
}

##### echo_log
#
# print a message on both stdout and log file
# usage: echo_log message

function echo_log () {
    echo "$1" | tee -a "$log"
}

##### check_path
#
# check if the directory exist
# if it doesn't, print to stdout and logfile then exit
# usage: check_path path

function check_path () {
    if [[ ! -d "$1" ]]; then
        exit_on_error "1" "Error $1 doesn't exists"
    fi
}
##########################################
#
#               Main
#
##########################################

# check main folders
check_path "$prog_path"
check_path "$work_path"
check_path "$archives_path"
check_path "$log_path"

# Flush logs after LogMaxDay reached
echo_log "Flush logs"
find "$log_path" -name "${prog_name}-*log" -type f -mtime +$log_max_day -print -delete 2>&1 | tee -a "$log"

# Enter in work directory
cd "${work_path}" >> "$log" 2>&1 || exit_on_error "1" "Error entering in ${work_path}"
echo_log "Entering in ${work_path}"

# select items, avoid .${hash_ext} and compressed files
items=$(find . -maxdepth 1 -type f -name "$file_pattern")

echo_log "items: $items"

error_code=0

# process files
for item in $items; do

    echo_log "current item: $item" 

    current_item_name="$item"

    # compress last item 
    "$compress_prog" "${current_item_name}.${compress_ext}" "${current_item_name}"
    if [[ "$?" -eq "0" ]]; then
        echo_log "File compressed ${current_item_name}.${compress_ext}"
    else
        echo_log "Error compressing file compressed ${current_item_name}.${compress_ext}"
    fi
         
    current_item_name="${current_item_name}.${compress_ext}"
    
    # Hash zip file
    "$hash_prog" "${current_item_name}" > "${current_item_name}.${hash_ext}"
    if [[ "$?" -eq "0" ]]; then
        echo_log "File hash created ${current_item_name}.${hash_ext}"
    else
        echo_log "Error creating file hash ${current_item_name}.${hash_ext}"
    fi
 
    # send files to the remote server
    sftp_cmd "put" "${dst_path}" "${current_item_name}"
    
    if [[ "$?" -eq "0" ]]; then
        # send hash files to the remote server
        sftp_cmd "put" "${dst_path}" "${current_item_name}.${hash_ext}"
    fi

    # remove compressed file
    echo_log "removing compressed and hash files"
    rm -v "${current_item_name}" 2>&1 | tee -a "$log"
    rm -v "${current_item_name}.${hash_ext}" 2>&1 | tee -a "$log"
    
    # move file to archive
    echo_log "move original file to archive"
    mv -v "${item}" "${archives_path}/${item}" 2>&1 | tee -a "$log"
    
done

# exiting with ErrorCode as RC
exit_on_error "$error_code" "End"

