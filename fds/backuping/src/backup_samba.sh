#!/bin/bash

#*
#* Backuping samba shares.
#*
#* @author Michal Malohlava
#* @date 11.2.2008
#* 
#* Params:
#*  -c <file>	path to config file with directories to backup
#*  -m  		do month backup (full) (DEFAULT)
#*  -d  		do daily backup (incremental - only files modified during last 1 (default) day
#*  -p <days>	change incremental backup to backup files modified during last <n> days
#*  -h 			show this help
#*  -v			print version

SCRIPT_DIR=$(cd  "$(dirname "$0")"; pwd)

# #### #
# INIT #
# #### #

#
# import library
# 
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/config_samba.sh"

#
# Init logging
# 
init_log ${LOG_DIR} ${LOG_DIRS_FILENAME}
log_simple "=========== [ Start of $0 - `date +%c`] ============="

# declare temporary variable to store logs
declare LOG_TEMP

function print_usage() {
cat <<EOF

$(basename $0) - samba backuper (version $VERSION)

Params:
  -c <file>	path to config file with directories to backup
  -m  		do month backup (full) (DEFAULT)
  -d  		do daily backup (incremental - only files modified during last 1 (default) day
  -p <days>	change incremental backup to backup files modified during last <n> days
  -h		show this help
  -v 		print version

EOF
}

function print_version() {
	echo "$(basename $0) - samba backuper (version $VERSION)"
}

function die() {
		log "!!! $1 !!!"
		mail -s "${MAIL_FAILURE_SUBJECT}" "${MAIL_CC_ADDR}" ${MAIL_ADDR} <<EOF
Host: $(hostname)
Date: $(date +'%F %T')

Script: $0
Message: $1

Log tail:
$(tail -n100 ${LOG_FILE})

EOF
		exit 1
}

function die_softly() {
        log "! $1 !"

        LOG_TEMP="${LOG_TEMP}
        ================ log entry =================
        Message: $1
        Date: $(date +'%F %T')

        Log tail:
        $(tail -n10 ${LOG_FILE})
        =============== end of entry ==============="
}

function do_month_clean() {
	L_DIR="$1/../"
	L_LAST_MONTH_DIR="${L_DIR}$(date -d -1month +%Y_%m)/"
	log "   - removing last month directory ${L_LAST_MONTH_DIR}"
	[ -e "${L_LAST_MONTH_DIR}" ] && rm -r "${L_LAST_MONTH_DIR}"

	L_LAST_MONTH_DIR="${L_DIR}/../daily/$(date -d -2month +%Y_%m)/"
	log "   - removing last month daily directory ${L_LAST_MONTH_DIR}"
	[ -e "${L_LAST_MONTH_DIR}" ] && rm -r "${L_LAST_MONTH_DIR}"
}

function read_config_and_do_backup() {
		if [ ! -e "$CONFIG_FILE" ]; then
				die "Cannot find file $CONFIG_FILE"
		fi

		log " - parse config $CONFIG_FILE"

		
		while read ITEM; do
				# skip comments
				L_IS_COMMENT=`expr match "$ITEM" "#.*"`
				[ ${L_IS_COMMENT} -gt 0 ] && continue;

				L_SAMBA_DIR=${ITEM% *}
				L_TARGET_DIR=${ITEM#* }/${BACKUP_TYPE}/
				case "$BACKUP_TYPE" in
				"month")
					L_TARGET_DIR=${L_TARGET_DIR}/$(date +%Y_%m)/
					;;
				"daily")
					L_TARGET_DIR=${L_TARGET_DIR}/$(date +%Y_%m)/$(date +%d)/
					;;
				esac

				T_FILENAME=$(get_filename_from_sambadir ${L_SAMBA_DIR})
				check_dir ${L_TARGET_DIR}
				L_OUTPUT_FILE="${L_TARGET_DIR}/${T_FILENAME}.zip"

				log "   - backuping samba dir ${L_SAMBA_DIR} to ${L_OUTPUT_FILE}"
				
				case "$BACKUP_TYPE" in
				"month")
					do_month_backup "$L_SAMBA_DIR" "$L_OUTPUT_FILE"
					do_month_clean "${L_TARGET_DIR}"
					;;
				"daily")
					do_daily_backup "$L_SAMBA_DIR" "$L_OUTPUT_FILE"
					;;
				esac

				log "     OK"
		done < "$CONFIG_FILE"
}


function do_month_backup() {
	local L_SMB_DIR=$1
	local L_FILENAME=$2

	log "   - mounting ${L_SMB_DIR} to ${SAMBA_MOUNT_POINT}"
	smbmount "${L_SMB_DIR}" "${SAMBA_MOUNT_POINT}" "${SMBCLIENT_OPTS}" >> ${LOG_FILE} 2>&1 || { die_softly "Cannot mount ${L_SMB_DIR}"; return 1; }
	
	log "   - calling: zip -r -1 ${L_FILENAME} ${SAMBA_MOUNT_POINT}"
	(
	cd "${SAMBA_MOUNT_POINT}"
	#zip -r -1 "${L_FILENAME}" "${SAMBA_MOUNT_POINT}" >> ${LOG_FILE} 2>&1
	zip -r -1 "${L_FILENAME}" . >> ${LOG_FILE} 2>&1
	)

	log "   - unmounting ${SAMBA_MOUNT_POINT}"
	smbumount "${SAMBA_MOUNT_POINT}" >> ${LOG_FILE} 2>&1 || { die_softly "Cannout umount ${L_SMB_DIR}";  return 1; }
}

function do_daily_backup() {
	local L_SMB_DIR=$1
	local L_FILENAME=$2

	log "   - mounting ${L_SMB_DIR} to ${SAMBA_MOUNT_POINT}"
	smbmount "${L_SMB_DIR}" "${SAMBA_MOUNT_POINT}" "${SMBCLIENT_OPTS}" >> ${LOG_FILE} 2>&1 || { die "Cannout mount ${L_SMB_DIR}"; return 1; }

	#find "$L_SMB_DIR" -mtime ${DAYS_NUMBER} | zip -1 "$L_FILENAME" -@
	DAY_PRIOR_NOW=$(date -d -${DAYS_NUMBER}day +%F)
	log "   - calling zip -r -1 -t ${DAY_PRIOR_NOW} ${L_FILENAME} ${SAMBA_MOUNT_POINT}"
	(
	cd "${SAMBA_MOUNT_POINT}"
	#zip -r -1 -t "${DAY_PRIOR_NOW}" "${L_FILENAME}" "${SAMBA_MOUNT_POINT}" >> ${LOG_FILE} 2>&1
	zip -r -1 -t "${DAY_PRIOR_NOW}" "${L_FILENAME}" . >> ${LOG_FILE} 2>&1
	)

	log "   - unmounting ${SAMBA_MOUNT_POINT}"
	smbumount "${SAMBA_MOUNT_POINT}" >> ${LOG_FILE} 2>&1 || { die "Cannot umount ${L_SMB_DIR}"; return 1; }
}

function report_log() {
        [ -z "$LOG_TEMP" ] && return 0
        

        mail -s "${MAIL_RECOVERABLE_FAILURE_SUBJECT}" "${MAIL_CC_ADDR}" ${MAIL_ADDR} <<EOF
Host: $(hostname)
Date: $(date +'%F %T')

Script: $0
Message: cummulative log

Log:
${LOG_TEMP}

EOF
}


# ############ #
# MAIN PROGRAM #
# ############ #

DATE=`date +%F`

if [ $# -eq 0 ]; then
	print_usage
	exit 0
fi

while [ $# -gt 0 ]; do
	case "$1" in
	"-v") 
  		print_version
		exit 0
		;;

	"-h")
		print_usage
		exit 0
		;;
	"-c")
		shift
		CONFIG_FILE="$1"
		;;
	"-m")
		BACKUP_TYPE="month"
		;;
	"-d") 
		BACKUP_TYPE="daily"
		;;
	"-p")
		shift
		DAYS_NUMBER="$1"
		;;
	esac

	shift
done

case "$BACKUP_TYPE" in
"month")
	log " - doing month backup"
	;;
"daily")
	log " - doing daily backup"
	;;
esac

# check temporary mount point
check_dir "$SAMBA_MOUNT_POINT"

read_config_and_do_backup

report_log

log_simple "=========== [ End of $0 - `date +%c`] =============\n"
