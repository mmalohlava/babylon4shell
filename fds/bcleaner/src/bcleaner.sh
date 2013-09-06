#!/bin/bash

# ##################################
# 
# Cleaning of created backups 
#
# Author: Michal Malohlava
# modry.cz
# #################################

SCRIPT_DIR=$(cd  "$(dirname "$0")"; pwd)

#
# import library
# 
CONFIG_FILE="$1"

if [ -e "${CONFIG_FILE}" ]; then
	source "${CONFIG_FILE}"
else
	echo "No config file given ... exiting..."
	exit
fi

function log() {
		NOW="`date +'%F %T'`"
		
		echo -e "[${NOW}] $1" >> ${LOG_PATH}
		#echo "$1"
}

function remove_file() {
	FILE_TO_REMOVE=$1
	log " - removing file ${FILE_TO_REMOVE}"
	rm -f ${FILE_TO_REMOVE}
}

#log 
log " ====== START of cleaning of old backups ======"

for ITEM in ${BACKUP_DIR_CLEAR_LIST} ; do
		L_DIR=${ITEM%=*}
		L_DAYS=${ITEM#*=}

		# log
		log "directory ${L_DIR}, max. days ${L_DAYS}"
		
		if [ -d ${L_DIR} ]; then
			find "${L_DIR}" -type f -ctime +${L_DAYS} | while read LINE; do
				remove_file $LINE
			done
		else
			log "[!!!] - ${L_DIR} does not exist"
		fi
done

#log
log "====== END of cleaning of old backups ======"

