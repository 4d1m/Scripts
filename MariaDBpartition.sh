#!/bin/bash
#title                  :mariaDBpartition.sh
#description            :This script makes sure that the weekly table partitions are created and deleted
#date                   :29/06/2018
#version                :0.0.1
#usage                  :./mariaDBpartition.sh
#notes                  : Please fill in all the relevant informations; there is only a 26 week retention
#=====================================================================

#Log file for the script
LOG_FILE='/var/log/PartitionMariaDB.log'
#Path to email binary
MAIL='/usr/bin/mail'
#Person to receive the email
DESTINATION=''
#Name of the database
SCHEMA=''
#Name of the table to be partitioned
TABLE=''
#Path to mysql binary (usually /usr/bin/mysql)
MYSQL=''

#Some date variables
CURWEEK=y`date +%Y`w`date +%W`;
NEXTWEEKTWO=y`date +%Y -d'+1 week'`w`date +%W -d'+1 week'`;
PARTITION26=y`date +%Y -d'-26 week'`w`date +%W -d'-26 week'`;
NEXTSUNDAY=`date +%Y-%m-%d -d'2 monday'`
# Make temp files
PARTITION_LIST=`mktemp`;
REMOVE_LIST=`mktemp`;




# Get partition list
echo -ne "Getting the partition list ... "
echo -ne "Getting the partition list ... \n" >> $LOG_FILE
lastrun_check=`echo "SELECT PARTITION_NAME FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA = '$SCHEMA' AND TABLE_NAME = '$TABLE' ORDER BY PARTITION_NAME ASC" | $MYSQL | sed 1d > $PARTITION_LIST | tee -a $LOG_FILE`
if [ "$?" != "0" ]; then
    echo -ne "ERROR!\n Couldn't get the partition list.\n\n" | tee -a $LOG_FILE
        echo "Check error log" | $MAIL -s "Script error" $DESTINATION
        exit
else
        echo -ne "OK\n" | tee -a $LOG_FILE
fi


# Add next week partition if not present
echo -ne "Create the partition for next week... "
echo -ne "Create the partition for next week... \n" >> $LOG_FILE
if [ 0 -eq `grep $NEXTWEEKTWO $PARTITION_LIST | wc --lines` ]; then
lastrun_check=`$MYSQL -D$SCHEMA -e"ALTER TABLE $TABLE REORGANIZE PARTITION maxi INTO (PARTITION $NEXTWEEKTWO VALUES LESS THAN (UNIX_TIMESTAMP('$NEXTSUNDAY')),PARTITION maxi VALUES LESS THAN ( MAXVALUE ))"`
if [ "$?" != "0" ]; then
    echo -ne "ERROR!\n Couldn't add the partition: $NEXTWEEKTWO.\n\n" | tee -a $LOG_FILE
        echo "Check error log" | $MAIL -s "Script error" $DESTINATION
        exit
else
        echo -ne "Added partition: $NEXTWEEKTWO ($NEXTSUNDAY)\n" | tee -a $LOG_FILE
fi
else
        echo -ne "INFO!\n The partition $NEXTWEEKTWO to be created is already present in the database.\n\n" | tee -a $LOG_FILE
fi

# Get partition to be purged
echo -ne "Getting the partitions to be truncated ... "
echo -ne "Getting the partitions to be truncated ... \n" >> $LOG_FILE
egrep "($PARTITION26)" $PARTITION_LIST > $REMOVE_LIST
if [ 0 -eq `cat $REMOVE_LIST | wc --lines` ]; then
        echo -ne "INFO!\n There is no partition to be deleted.\n\n" | tee -a $LOG_FILE
        #echo "Check error log" | $MAIL -s "Script error" $DESTINATION
else
echo -ne "OK\n" | tee -a $LOG_FILE
# Remove all unecessary partitions
echo -ne "Drop the partition ... "
echo -ne "Drop the partition ... \n" >> $LOG_FILE

for PARTITION in `cat $REMOVE_LIST`;
do
lastrun_check=`$MYSQL -D$SCHEMA -e"ALTER TABLE $TABLE DROP PARTITION $PARTITION"`
if [ "$?" != "0" ]; then
    echo -ne "ERROR!\n Couldn't delete the partition: $PARTITION.\n\n" | tee -a $LOG_FILE
        echo "Check error log" | $MAIL -s "Script error" $DESTINATION
        exit
else
        echo -ne "OK\n" | tee -a $LOG_FILE
fi
done
fi

# Cleanup
rm -f $PARTITION_LIST
rm -f $REMOVE_LIST

exit 0;
