#!/bin/bash

##############################
#
# Simple space disk controller
#
# @author Michal Malohlava
# ###########################

MAIL="TO"
HOSTNAME=`hostname`

DEV_MONITOR="/dev/hda5=87"


function sendMail() {
	echo $1
	echo $2
	mail -s "${HOSTNAME}: quota exceeded!" "$MAIL" <<EOF
	Disk: $1
	df -h: $2
EOF
}

for item in ${DEV_MONITOR} ; do
DEV=`echo ${item} | sed -ne "s/\([^=]*\)=.*/\1/p"`
LIMIT=`echo ${item} | sed -ne "s/[^=]*=\(.*\)/\1/p"`

DF_OUTPUT=`df -h | grep ${DEV}`
if [ -z "$DF_OUTPUT" ]; then
 continue;
fi

PERCENT_USAGE=`echo $DF_OUTPUT | sed -e "s/\ \{2,\}/ /g" | cut -d" " -f5 | sed -e "s/\%//"`
echo $DF_OUTPUT
echo $PERCENT_USAGE

if [ "$PERCENT_USAGE" -gt "$LIMIT" ]; then
		sendMail ${DEV} ${DF_OUTPUT}
fi

done
