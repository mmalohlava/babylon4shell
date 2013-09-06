#!/bin/bash
# setup.sh -- created 2009-05-18, <+NAME+>
# @Last Change: 24-Dez-2004.
# @Revision:    0.0

LOG="log-missing-props.txt"
MLOG="log-missing-id.txt"

[ -e "$LOG" ] && rm $LOG
[ -e "$MLOG" ] && rm $MLOG

find . -name "*.java" | while read jfile; do

svn_props=`svn pl $jfile`

if [ -z "$svn_props" ]; then
        echo "$jfile"  >> $LOG
        echo "Missing props: svn:eol-style, svn:keywords" >> $LOG
        ID_GREP=`grep -e "$Id[^:]" ${jfile}`
        grep -e "Id[^:]" ${jfile}
        
        if [ -z "$ID_GREP" ]; then
                echo $jfile >> $MLOG
                echo "Missing: Id keyword in comment" >> $LOG
        fi

        svn info $jfile | grep "Author" >> $LOG

        echo "----------------------------------------" >> $LOG
        echo "$jfile"
        echo "----------------------------------------"
        
        svn ps svn:eol-style native "$jfile" >> $LOG 2>&1
        svn ps svn:keywords Id "$jfile" >> $LOG 2>&1
fi

done

# vi: 
