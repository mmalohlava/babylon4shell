#!/bin/bash

# ##################################
# 
# Backuping of postgre database
#
# Author: Michal Malohlava
# modry.cz
#
# @param config file with parameters to overide (optional)
#
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

##
## check for config overriden 
##
if [ ! -z $1 ]; then
	log " - parse config $1"
	source "$1"
fi 

DATE=`date +%F`
DB_USER=postgres
DB_PASS=nic
DB_DB=forecaster_production

FILE_NAME="db_${DB_DB}_${DATE}.backup"
OUTPUT_DIR=${BACKUP_DB_POSTGRES_DIR}${DB_DB}/
REMOTE_OUTPUT_DIR=${REMOTE_DB_POSTGRES_DIR}${DB_DB}/
OUTPUT_FILE=${OUTPUT_DIR}${FILE_NAME}

log " - checking output dir ${OUTPUT_DIR}"
check_dir ${OUTPUT_DIR}

log " - start backup ${DB_DB} into ${OUTPUT_FILE}"
backup_db_postgresql ${DB_USER} ${DB_PASS} ${DB_DB} "${OUTPUT_FILE}" >>${LOG_FILE} 2>&1
log " - backup finished, result: $?"

#
# copy it to remote server
# 
log " - start remote copying to ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_OUTPUT_DIR}/${FILE_NAME}"
copy_scp ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_SCRIPT}" "${REMOTE_OUTPUT_DIR}" "${FILE_NAME}" "${OUTPUT_FILE}" >>${LOG_FILE} 2>&1
log " - remote copying finished, result: $?"

#
# compute hash
#
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

#
# End
#
log_simple "=========== [ End of $0 - `date +%c`] =============\n"

