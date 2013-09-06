#
# default configuration file for samba backuper
#
BACKUP_HOME=/home/accounts/backuper/

LOG_DIR=${BACKUP_HOME}log/
LOG_DIRS_FILENAME=backup_samba.log

VERSION=1.0.0

BACKUP_TYPE="month"
DAYS_NUMBER=1

SAMBA_MOUNT_POINT=${BACKUP_HOME}mnt/samba/
SMBCLIENT_OPTS="-o guest,ro,user=guest,password="

MAIL_FAILURE_SUBJECT="Samba backup failed"
MAIL_RECOVERABLE_FAILURE_SUBJECT="Samba backup: some error occured"
MAIL_ADDR=
MAIL_CC_ADDR=
