#!/bin/bash

# ##################################
# 
# Backuping of all mysql database
#
# Author: Michal Malohlava
# modry.cz
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
init_log ${LOG_DIR} ${LOG_DB_FILENAME}
log_simple "=========== [ Start of $0 - `date +%c`] ============="

DATE=`date +%F`
DB_USER=root
DB_PASS=JapAthMach
DB_SKIP_DB="test information_schema"

# Get all database list first
DATABASES="$(get_list_all_mysql_db ${DB_USER} ${DB_PASS})"

for DB in $DATABASES; do
    skipdb=-1
    if [ "$DB_SKIP_DB" != "" ]; then
		for i in $DB_SKIP_DB ; do
			[ "$DB" == "$i" ] && skipdb=1 || :
		done
	fi
    
    if [ "$skipdb" == "-1" ] ; then
		FILE_NAME="db_${DB}_${DATE}.backup.gz"
		OUTPUT_DIR=${BACKUP_DB_MYSQL_DIR}${DB}/
		OUTPUT_FILE=${OUTPUT_DIR}${FILE_NAME}
		REMOTE_OUTPUT_DIR=${REMOTE_DB_MYSQL_DIR}${DB}/

		log " - checking output dir ${OUTPUT_DIR}"
		check_dir ${OUTPUT_DIR}
		
		log " - start backup ${DB} into ${OUTPUT_FILE}"
		backup_db_mysql ${DB_USER} ${DB_PASS} ${DB} "${OUTPUT_FILE}" >>${LOG_FILE} 2>&1
		log " - backup finished, result: $?"

		log " - start remote copying to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_OUTPUT_DIR}/${FILE_NAME}"
		copy_scp ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_SCRIPT}" "${REMOTE_OUTPUT_DIR}" "${FILE_NAME}" "${OUTPUT_FILE}" >>${LOG_FILE} 2>&1
		log " - remote copying finished, result: $?"

		LOCAL_FILE_HASH=`local_file_hash ${OUTPUT_FILE}`
		REMOTE_FILE_HASH=`remote_file_hash ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_OUTPUT_DIR}${FILE_NAME}"`

		if [ "${LOCAL_FILE_HASH}" != "${REMOTE_FILE_HASH}" ]; then
			log " - hash of files are not identical!!!"
			mail -s "${HASH_FAILED_SUBJECT}" ${MAIL_ADDRESS} <<EOF
Host: `hostname`
Date: `date +'%F %T'`

Script: $0
Database: $DB_DB
Output dir: ${OUTPUT_DIR}
Output file: ${OUTPUT_FILE}
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

		log_simple "\n"

    fi
done

log_simple "=========== [ End of $0 - `date +%c`] =============\n"

