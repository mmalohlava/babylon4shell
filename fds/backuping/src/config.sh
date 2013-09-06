#!/bin/bash
#
# Backuping main home
# 
BACKUP_HOME=/home/backup/

#
# Info directory - for storing system information
# 
SYSTEM_INFO_DIR=/var/spool/fdsbackup/

#
# Directory for backuping databases
# 
BACKUP_DB_DIR=${BACKUP_HOME}db/
BACKUP_DB_POSTGRES_DIR=${BACKUP_DB_DIR}postgresql/
BACKUP_DB_MYSQL_DIR=${BACKUP_DB_DIR}mysql/

#
# Directory for backuping images
#
BACKUP_IMAGES_DIR=${BACKUP_HOME}images/
BACKUP_DAILY_IMAGES_DIR="${BACKUP_IMAGES_DIR}/daily/"
BACKUP_WEEKLY_IMAGES_DIR="${BACKUP_IMAGES_DIR}/weekly/"
TMP_BACKUP_WEEKLY_IMAGES_DIR="${BACKUP_IMAGES_DIR}/week_last/"

#
# Directory for backuping directories
# 
BACKUP_DIRS_DIR=${BACKUP_HOME}dir/

#
# Log dir
#
LOG_DIR=${BACKUP_HOME}log/
LOG_DB_FILENAME=backup_db.log
LOG_IMG_FILENAME=backup_image.log
LOG_DIRS_FILENAME=backup_dirs.log


#
# Remote locations
# 
REMOTE_DIR=/mnt/backup/fds/
REMOTE_DB_DIR=${REMOTE_DIR}db/
REMOTE_DB_POSTGRES_DIR=${REMOTE_DB_DIR}postgresql/
REMOTE_DB_MYSQL_DIR=${REMOTE_DB_DIR}mysql/

REMOTE_IMAGES_DIR="${REMOTE_DIR}images/"
REMOTE_WEEKLY_IMAGES_DIR="${REMOTE_IMAGES_DIR}weekly/"
REMOTE_DAILY_IMAGES_DIR="${REMOTE_IMAGES_DIR}daily/"

REMOTE_DIRS_DIR="${REMOTE_DIR}dir/"

REMOTE_USER=fds
REMOTE_HOST=svetle.modry.cz

REMOTE_SCRIPT="./bin/do_backup.sh"
REMOTE_IMG_SCRIPT="./bin/do_backup.sh"
REMOTE_START_IMG_BACKUP_SCRIPT="./bin/do_img_backup.sh"
REMOTE_START_DAILY_IMG_BACKUP_SCRIPT="./bin/do_daily_img_backup.sh"

IDAILY_TIMESTAMP_FILE="${SYSTEM_INFO_DIR}idaily_timestamp"

#
# Location of images
#
FLEURBANK_USER_HOME=/home/fleurbank/
IMAGES_SOURCE_DIR=${FLEURBANK_USER_HOME}data/
# list of names for directories where images are stored
IMAGE_DIRS="files bitmaps print thumbs"

#
# LOCK FILES
# 
DAILY_IMAGE_LOCK=${SYSTEM_INFO_DIR}.lock_daily

#
# MAIL setting
#
MAIL_ADDRESS=""
HASH_FAILED_SUBJECT="fleurbank.com backuping - hash failed"
IMAGE_FAILED_SUBJECT="fleurbank.com backuping - image transfer failed"
