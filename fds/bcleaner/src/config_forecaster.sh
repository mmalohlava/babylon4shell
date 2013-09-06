#!/bin/bash
#
# Backuping main home
# 
BACKUP_HOME=/home/backup/

#
# Directory for backuping databases
# 
BACKUP_DB_DIR=${BACKUP_HOME}db/
BACKUP_DB_POSTGRES_DIR=${BACKUP_DB_DIR}postgresql/
BACKUP_DB_MYSQL_DIR=${BACKUP_DB_DIR}mysql/

#
# Directory for backuping directories
# 
BACKUP_DIRS_DIR=${BACKUP_HOME}dir/

#
# Log dir
#
LOG_DIR=${BACKUP_HOME}log/
LOG_BCLENEAR_FILENAME=bcleaner.log
LOG_PATH=${LOG_DIR}${LOG_BCLENEAR_FILENAME}

#
# MAIL setting
#
MAIL_ADDRESS=""
HASH_FAILED_SUBJECT="fleurbank.com backuping - hash failed"
IMAGE_FAILED_SUBJECT="fleurbank.com backuping - image transfer failed"

# specifies list of directories and number of days
BACKUP_DIR_CLEAR_LIST="${BACKUP_DB_POSTGRES_DIR}=30
${BACKUP_DB_MYSQL_DIR}=30
${BACKUP_DIRS_DIR}=30"
