#!/bin/bash

# ##################################
# 
# Backuping of selected directories 
#
# Author: Michal Malohlava
# modry.cz
#
# @param config file with directories list to backup (compulsory)
# @param config file with parameters to overide (optional)
# #################################

SCRIPT_DIR=$(cd  "$(dirname "$0")"; pwd)

#
# import library
# 
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/config.sh"


#
# Init logging
# 
init_log ${LOG_DIR} ${LOG_DIRS_FILENAME}
log_simple "=========== [ Start of $0 - `date +%c`] ============="

#
# Check input file
#
if [ -z $1 ]; then
		log " - no input file was given. Exiting"
		exit 1
fi

if [ ! -z $2 ]; then
		log " - parse config $2"
		source "$2"
fi

DATE=`date +%F`

declare -a OUTPUT_FILES_ARRAY

while read ITEM; do
		L_DIR=${ITEM% *}
		L_INCLUDE_SUBDIRS=${ITEM#* }

		T_FILENAME=$(get_filename_from_dir ${L_DIR})
		L_OUTPUT_DIR=${BACKUP_DIRS_DIR}${T_FILENAME}/
		check_dir ${L_OUTPUT_DIR}
								
		L_FILENAME="${DATE}_${T_FILENAME}.tar.bz2"
		L_OUTPUT_FILE=${L_OUTPUT_DIR}${L_FILENAME}
		OUTPUT_FILES_ARRAY[${#OUTPUT_FILES_ARRAY[*]}]="${T_FILENAME}=${L_OUTPUT_FILE}"

		log " - backuping directory ${L_DIR} to ${L_OUTPUT_FILE}, including subdirs: ${L_INCLUDE_SUBDIRS}"
		
		case ${L_INCLUDE_SUBDIRS} in 
			"INCLUDE_SUBDIRS") 
				L_TAR_PARAMS=""
				;;
			"NOT_INCLUDE_SUBDIRS")
				L_TAR_PARAMS="--no-recursion"
				L_DIR="${L_DIR}*"
				;;
			*) L_TAR_PARAMS=""
				;;
		esac
		L_TAR_PARAMS="--exclude *.log ${L_TAR_PARAMS}"
		
		tar_dir "${L_DIR}" "${L_OUTPUT_FILE}" "${L_TAR_PARAMS}" >>${LOG_FILE} 2>&1
done < "$1"

for ITEM in ${OUTPUT_FILES_ARRAY[@]} ; do
		L_DIR=${ITEM%=*}
		L_INPUT_FILE=${ITEM#*=}
		L_FILENAME=$(basename ${L_INPUT_FILE})

		L_REMOTE_DIR=${REMOTE_DIRS_DIR}${L_DIR}/

		log " - start remote copying ${L_INPUT_FILE} to ${REMOTE_USER}@${REMOTE_HOST}:${L_REMOTE_DIR}/${L_FILENAME}"
		copy_scp ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_SCRIPT}" "${L_REMOTE_DIR}" "${L_FILENAME}" "${L_INPUT_FILE}" >>${LOG_FILE} 2>&1
		log " - remote copying finished, result: $?"
		
		LOCAL_FILE_HASH=`local_file_hash ${L_INPUT_FILE}`
		REMOTE_FILE_HASH=`remote_file_hash ${REMOTE_USER} ${REMOTE_HOST} "${L_REMOTE_DIR}${L_FILENAME}"`

		if [ "${LOCAL_FILE_HASH}" != "${REMOTE_FILE_HASH}" ]; then
			log " - hash of files are not identical!!!"
			mail -s "${HASH_FAILED_SUBJECT}" ${MAIL_ADDRESS} <<EOF
Host: `hostname`
Date: `date +'%F %T'`

Script: $0
Output dir: ${L_INPUT_FILE}
Output file: ${L_FILENAME}
Remote file: ${REMOTE_OUTPUT_DIR}${FILE_NAME}

Hash failed:
 local file:  ${LOCAL_FILE_HASH}
 remote file: ${REMOTE_FILE_HASH}
EOF
		else
				log " - hash of local and remote files are identical:"
		fi
		log "\t * local file:  ${LOCAL_FILE_HASH}"
		log "\t * remote file: ${REMOTE_FILE_HASH}"
done

log_simple "=========== [ End of $0 - `date +%c`] =============\n"
