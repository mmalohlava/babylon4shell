#!/bin/bash

#
# Simple library of function for backuping
#
# Author: Michal Malohlava
# Date: 15.4.2007
#

function copy_ftp() {
		F_FTP_ADDRESS=$1
		F_FTP_USER=$2
		F_FTP_PASSWORD=$3
}

function copy_scp() {
	S_USER=$1
	S_HOSTNAME=$2
	S_REMOTE_SCRIPT=$3
	S_REMOTE_DIR=$4
	S_REMOTE_FILE_NAME=$5
	S_COPY_FILE=$6

	ssh "${S_USER}@${S_HOSTNAME}" "${S_REMOTE_SCRIPT}" "${S_REMOTE_DIR}" "${S_REMOTE_FILE_NAME}" < "${S_COPY_FILE}" 
}

# ##############################
# Dump database 
#  - custom format
#  - dump blobs
#  
# @param User name
# @param User password
# @param Database to dump name
# @param Output file name
# @param Additional parameters
# ##############################
function backup_db_postgresql() {
		export PGUSER="$1"
		export PGPASSWORD="$2"
		export PGDATABASE="$3"
		B_OUTPUT_FILE="$4"
		B_ADDITIONAL_PARAMS=$5

		pg_dump --file="${B_OUTPUT_FILE}" --format=c --blobs ${B_ADDITIONAL_PARAMS}
}

# ##############################
# Dump mysql database
#  - produce gzipped file
#
# @params are same like above
#
# ##############################
function backup_db_mysql() {
		B_USER=$1
		B_PASSWORD=$2
		B_DB=$3
		B_OUTPUT_FILE=$4
		B_ADDITIONAL_PARAMS=$5
    	
		mysqldump -u $B_USER -p$B_PASSWORD ${B_ADDITIONAL_PARAMS} $B_DB | gzip -9 > ${B_OUTPUT_FILE}
}

# ##############################
#
# Check if directory exist. And if not, then create it.
#
# @param path to directory
#
# ##############################
function check_dir() {
		local DIR="$1"

		if [ ! -d "${DIR}" ]; then
				mkdir --parents ${DIR}
		fi
}

# ##############################
# Create timestamp file
#
# @param full path of timestamp file
# ##############################
function create_timestamp() {
		local TIMESTAMP_FILE="$1"

		date > ${TIMESTAMP_FILE}
}

# ##############################
# Get a list of all databases
#
# @params user
# @params password
# 
# ##############################
function get_list_all_mysql_db() {
	DB_USER=$1
	DB_PASS=$2

	mysql -u $DB_USER -p$DB_PASS -Bse "show databases"
}

function init_log() {
		L_DIR=$1
		L_FILENAME=$2

		if [ ! -e ${L_DIR} ]; then
				mkdir -p ${L_DIR}
		fi

		export LOG_FILE="${L_DIR}/${L_FILENAME}"
}

function log() {
		NOW="`date +'%F %T'`"
		
		echo -e "[${NOW}] $1" >> ${LOG_FILE}
}

function log_simple() {
		echo -e "$1" >> ${LOG_FILE}
}

function local_file_hash() {
		sha1sum "$1" | cut -f1 -d\ 
}

function remote_file_hash() {
	S_USER=$1
	S_HOSTNAME=$2
	S_REMOTE_FILE=$3

	ssh "${S_USER}@${S_HOSTNAME}" sha1sum "${S_REMOTE_FILE}" | cut -f1 -d\ 
}

function local_dir_size() {
		du -s -b "$1" | cut -f1
}

function remote_dir_size() {
	S_USER=$1
	S_HOSTNAME=$2
	S_REMOTE_DIR=$3

	ssh "${S_USER}@${S_HOSTNAME}" du -s -b "${S_REMOTE_DIR}" | cut -f1 
}

# ##############################
#
# Copy safety given dir to given location
#
# @param source dir
# @param dest dir
# 
# ##############################
function copy_dir() {
		local F_SOURCE="$1"
		local F_DEST="$2"
		
		check_dir ${F_DEST}

		find "${F_SOURCE}" -type f -exec cp "{}" "${F_DEST}" \; 
}

function copy_new_files() {
		local F_SOURCE="$1"
		local F_DEST="$2"
		local I_TIMESTAMP="$3"
		
		check_dir ${F_DEST}

		find "${F_SOURCE}" -newer "${I_TIMESTAMP}" -type f -exec cp "{}" "${F_DEST}" \; 
}

function clean_dir() {
		local F_DIR="$1"

		rm -rf ${F_DIR}/*
}

# ##############################
#
# Copy safety given dir to given remote location
#
# @param source dir
# @param dest dir
# 
# ##############################
function copy_dir_remote() {
		local S_USER=$1
		local S_HOSTNAME=$2
		local S_REMOTE_SCRIPT=$3
		local S_REMOTE_DIR=$4
		local S_LOCAL_SOURCE_DIR=$5

		find "${S_LOCAL_SOURCE_DIR}" -type f -printf "%f %p\n" | while read F_FILENAME F_FILEPATH; do
			copy_scp "${S_USER}" "${S_HOSTNAME}" "${S_REMOTE_SCRIPT}" "${S_REMOTE_DIR}" "${F_FILENAME}" "${F_FILEPATH}"
		done
}

function execute_remote_script() {
		local S_USER=$1
		local S_HOSTNAME=$2
		local S_REMOTE_SCRIPT=$3

		shift 3

		ssh "${S_USER}@${S_HOSTNAME}" "${S_REMOTE_SCRIPT}" "$@"
}

function move_dir_recursively() {
		local S_SOURCE=$1
		local S_DEST=$2

		if [ -e "${S_DEST}" ]; then
				rm -rf "${S_DEST}"
		fi

		check_dir "$S_DEST"

		mv -f "${S_SOURCE}" "${S_DEST}"
}

function count_files_in_dir() {
		local I_DIR=$1

		local I_COUNT=`find "${I_DIR}" -maxdepth 1 -type f | wc -l`

		echo $I_COUNT
}

function count_new_files_in_dir() {
		local I_DIR="$1"
		local I_TIMESTAMP="$2"

		local I_COUNT=`find "${I_DIR}" -maxdepth 1 -newer "${I_TIMESTAMP}" -type f | wc -l`

		echo $I_COUNT
}

function wait_on_lock() {
		local I_LOCK="$1"

		while [ -e "${I_LOCK}" ]; do
				sleep 5
		done
}

function tar_dir() {
		local I_DIR=$1
		local I_OUTPUT=$2
		local I_PARAM=$3

		tar -c -j -f ${I_OUTPUT} ${I_PARAM} ${I_DIR}
}

function get_filename_from_dir() {
		local I_DIR=$1

		L_FILENAME=${I_DIR//\//.}
		L_FILENAME=${L_FILENAME#.}
		L_FILENAME=${L_FILENAME%.}

		echo $L_FILENAME
}

function get_filename_from_sambadir() {
		local I_DIR=$1

		L_FILENAME=${I_DIR//\/\//.}
		L_FILENAME=${L_FILENAME//\//.}
		L_FILENAME=${L_FILENAME#.}
		L_FILENAME=${L_FILENAME%.}

		echo $L_FILENAME
}
