#!/bin/bash

# ##################################
# 
# Backuping of daily differenced images
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
TODAY_DAY=`date +%u_%A`

#
# just create timestamp file
# 
log "- checking timestamp file"
check_dir ${SYSTEM_INFO_DIR}
if [ ! -e "${IDAILY_TIMESTAMP_FILE}" ]; then
		create_timestamp ${IDAILY_TIMESTAMP_FILE}
fi

log " - start local copying"
touch ${DAILY_IMAGE_LOCK}

for I_DIR_NAME in ${IMAGE_DIRS} ; do
		I_FULL_DIR="${IMAGES_SOURCE_DIR}${I_DIR_NAME}/"
		I_BACKUP_DIR="${BACKUP_DAILY_IMAGES_DIR}${TODAY_DAY}/${I_DIR_NAME}/"

		log " - cleaning dir ${I_BACKUP_DIR}"
		clean_dir ${I_BACKUP_DIR}
		
		log " - copy [${I_DIR_NAME}] images from ${I_FULL_DIR} to ${I_BACKUP_DIR}"
		I_COUNT=`count_new_files_in_dir ${I_FULL_DIR} ${IDAILY_TIMESTAMP_FILE}`
		log "\t* will copy ${I_COUNT} files"

		copy_new_files "${I_FULL_DIR}" "${I_BACKUP_DIR}" "${IDAILY_TIMESTAMP_FILE}" >>${LOG_FILE} 2>&1
		
		log " - end of copying [${I_DIR_NAME}] images"
done
log " - end of local copying"
#
# Set new timestamp
#
log " - creating new timestamp"
create_timestamp ${IDAILY_TIMESTAMP_FILE}


########################
# Remote file copying
########################

log " - start remote transfer to ${REMOTE_HOST}"
execute_remote_script ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_START_DAILY_IMG_BACKUP_SCRIPT}" "${REMOTE_DAILY_IMAGES_DIR}${TODAY_DAY}/" >>${LOG_FILE} 2>&1

for I_DIR_NAME in ${IMAGE_DIRS} ; do
		I_BACKUP_DIR="${BACKUP_DAILY_IMAGES_DIR}${TODAY_DAY}/${I_DIR_NAME}/"
		I_REMOTE_DIR="${REMOTE_DAILY_IMAGES_DIR}${TODAY_DAY}/${I_DIR_NAME}/"
		
		log " - remote copy [${I_DIR_NAME}] images from ${I_BACKUP_DIR} to ${I_REMOTE_DIR}"
		I_COUNT=`count_files_in_dir ${I_BACKUP_DIR}`
		log "\t\t* ${I_COUNT} files will be transfered" 
	
		copy_dir_remote ${REMOTE_USER} ${REMOTE_HOST} "${REMOTE_IMG_SCRIPT}" "${I_REMOTE_DIR}" "${I_BACKUP_DIR}" >>${LOG_FILE} 2>&1

		#
		# check size
		#
		I_LOCAL_SIZE=`local_dir_size ${I_BACKUP_DIR}`
		I_REMOTE_SIZE=`remote_dir_size ${REMOTE_USER} ${REMOTE_HOST} ${I_REMOTE_DIR}`
		if [ ${I_COUNT} -gt 0 ]; then 
				if [ "${I_LOCAL_SIZE}" != "${I_REMOTE_SIZE}" ]; then
					log " - size of directories are not identical!!!"
					mail -s "${IMAGE_FAILED_SUBJECT}" ${MAIL_ADDRESS} <<EOF
Host: `hostname`
Date: `date +'%F %T'`

Script: $0
Dir name: ${I_DIR_NAME}
Local dir: ${I_BACKUP_DIR}
Remote dir: ${I_REMOTE_DIR}

Size of directories differs:
 local dir:  ${I_LOCAL_SIZE}B
 remote dir: ${I_REMOTE_SIZE}B
EOF
				else
						log " - size of directories are same:"
				fi
			log "\t * size of local dir:  ${I_LOCAL_SIZE}B"
			log "\t * size of remote dir: ${I_REMOTE_SIZE}B"
		fi

		log " - end of copying [${I_DIR_NAME}] images"
done
log "- end of remote transfer"

rm -f ${DAILY_IMAGE_LOCK}

#
# End
#
log_simple "=========== [ End of $0 - `date +%c`] =============\n"

