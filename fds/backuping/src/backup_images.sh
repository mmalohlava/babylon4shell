#!/bin/bash

# ##################################
# 
# Backuping of all images
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
init_log ${LOG_DIR} ${LOG_IMG_FILENAME}
log_simple "=========== [ Start of $0 - `date +%c`] ============="

DATE=`date +%F`

log " - waiting for daily image backup"
wait_on_lock ${DAILY_IMAGE_LOCK}

log " - start local copying"

## move_dir_recursively "${BACKUP_WEEKLY_IMAGES_DIR}" "${TMP_BACKUP_WEEKLY_IMAGES_DIR}" >>${LOG_FILE} 2>&1
clean_dir ${BACKUP_WEEKLY_IMAGES_DIR}

for I_DIR_NAME in ${IMAGE_DIRS} ; do
		I_FULL_DIR="${IMAGES_SOURCE_DIR}${I_DIR_NAME}/"
		I_BACKUP_DIR="${BACKUP_WEEKLY_IMAGES_DIR}${I_DIR_NAME}/"
		
		log " - copy [${I_DIR_NAME}] images from ${I_FULL_DIR} to ${I_BACKUP_DIR}"
		I_COUNT=`count_files_in_dir ${I_FULL_DIR}`
		log "\t* will copy ${I_COUNT} files"

		copy_dir "${I_FULL_DIR}" "${I_BACKUP_DIR}" >>${LOG_FILE} 2>&1
		
		log " - end of copying [${I_DIR_NAME}] images"
done
log "- end of local copying"

log " - start remote transfer to ${REMOTE_HOST}"
log " - change remotely last backup"
execute_remote_script ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_START_IMG_BACKUP_SCRIPT}" "${REMOTE_WEEKLY_IMAGES_DIR}" >>${LOG_FILE} 2>&1

for I_DIR_NAME in ${IMAGE_DIRS} ; do
		I_BACKUP_DIR="${BACKUP_WEEKLY_IMAGES_DIR}${I_DIR_NAME}/"
		I_REMOTE_DIR="${REMOTE_WEEKLY_IMAGES_DIR}${I_DIR_NAME}/"
		
		log " - remote copy [${I_DIR_NAME}] images from ${I_BACKUP_DIR} to ${I_REMOTE_DIR}"
		I_COUNT=`count_files_in_dir ${I_BACKUP_DIR}`
		log "\t\t* ${I_COUNT} files will be transfered" 
	
		copy_dir_remote ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_IMG_SCRIPT}" "${I_REMOTE_DIR}" "${I_BACKUP_DIR}" >>${LOG_FILE} 2>&1
		
		log " - end of copying [${I_DIR_NAME}] images"
done
log "- end of remote transfer"

#
# End
#
log_simple "=========== [ End of $0 - `date +%c`] =============\n"

