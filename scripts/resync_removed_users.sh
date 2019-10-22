#!/bin/bash
##################################################################################
#
# Removes users from the duplicate user database if they no longer appear in the ILS.
#    Copyright (C) 2017  Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Copyright (c) Wed Jun 27 12:12:21 MDT 2018
# Rev:
#          0.0 - Dev.
#
##############################################################################
### This script creates a list of all user keys, then compares those that
### exist in the ILS
# Setup variables
#SERVER=sirsi\@eplapp.library.ualberta.ca
SERVER=sirsi\@edpt-t.library.ualberta.ca
LOCAL_DIR=$HOME/OnlineRegistration/olr-duplicate_user/delete
DELETE_USERS_FILE=$LOCAL_DIR/users_delete.txt
ALL_DUPLICATE_USER_KEYS_FILE=$LOCAL_DIR/all_duplicate_user_keys.txt
ALL_ILS_USER_KEYS_FILE=$LOCAL_DIR/all_ILS_user_keys.txt
PY_SCRIPT=$HOME/OnlineRegistration/olr-duplicate_user/scripts/duplicate_user.py
LOG=$HOME/OnlineRegistration/olr-duplicate_user/logs/duplicateDB_resync.log
## We use fully qualified paths, but will go to that directory just in case I forgot one.
cd $LOCAL_DIR
## Output all the user keys in the duplicate user database.
printf "Creating a list of all existing user keys from the doctype 'duplicate_user' in index 'epl'...\n" >&2
/usr/bin/python $PY_SCRIPT -a $ALL_DUPLICATE_USER_KEYS_FILE 2>&1 >>$LOG
printf "done\n" >&2
echo "["`date`"] Creating a list of all existing user keys from the doctype 'duplicate_user' in index 'epl' - COMPLETE." >>$LOG
if [ -s "$ALL_DUPLICATE_USER_KEYS_FILE" ]; then
    # Should look like a file where each line is a user key.
    # 854063
    # 854055
    # The output of the ILS queries is a file, each line looks like this.
    # 854063|
    ## If the file of all keys was produced, ask the ILS which are valid users.
    printf "Comparing all user keys with those in the ILS...\n" >&2
    cat $ALL_DUPLICATE_USER_KEYS_FILE | ssh $SERVER 'cat - | seluser -iU' 2>/dev/null >$ALL_ILS_USER_KEYS_FILE
    printf "done\n" >&2
    echo "["`date`"] Comparing all user keys with those in the ILS - COMPLETE." >>$LOG
    if [ -s "$ALL_ILS_USER_KEYS_FILE" ]; then
        ## now you have to compare the 2 files. Normally I would use diff.pl, but on this job we can use pipe.pl
        ## cat $ALL_DUPLICATE_USER_KEYS_FILE | pipe.pl -0$ALL_ILS_USER_KEYS_FILE -Mc0:c0?c0
        # 854063|854063
        # 854055
        ## All the lines that have a c1 field are in the ILS AND in the duplicate user database; that's good.
        ## All the lines that don't have a c1 field are only in the duplicate user database; remove these.
        printf "Filtering user keys to determine which to remove...\n" >&2
        cat $ALL_DUPLICATE_USER_KEYS_FILE | pipe.pl -0$ALL_ILS_USER_KEYS_FILE -Mc0:c0?c0 | pipe.pl -Zc1 >$DELETE_USERS_FILE
        printf "done\n" >&2
        echo "["`date`"] Filtering user keys to determine which to remove - COMPLETE." >>$LOG
        # 854055
        if [ -s "$DELETE_USERS_FILE" ]; then
            printf "Removing duplicate users from index 'epl', doc_type 'duplicate_user'.\n" >&2
            /usr/bin/python $PY_SCRIPT -d $DELETE_USERS_FILE 2>&1 >>$LOG
            ## now remove the user file so it doesn't get reprocessed, not dangerours if it doesn't but takes time.
            # rm $DELETE_USERS_FILE
            printf "done\n" >&2
            echo "["`date`"] Removal of invalid duplicate users from 'duplicate_user' database - COMPLETE." >>$LOG
        else
            printf "The duplicate user database is clean, no duplicate users were found.\n" >&2
            echo "["`date`"] The duplicate user database is clean, no duplicate users were found." >>$LOG
        fi
    else # The $ALL_ILS_USER_KEYS_FILE  didn't get created (the ILS didn't respond or ssh keys didn't work or ...)
        printf "There was a problem contacting the ILS, or it didn't respond.\n" >&2
        echo "["`date`"] There was a problem contacting the ILS, or it didn't respond." >>$LOG
        exit 1
    fi
else # The $ALL_DUPLICATE_USER_KEYS_FILE file is empty so the database isn't running, the query failed, the database is empty.
    printf "$ALL_DUPLICATE_USER_KEYS_FILE file wasn't created. The database isn't running, is empty, or the query failed.\n" >&2
    echo "["`date`"] $ALL_DUPLICATE_USER_KEYS_FILE file wasn't created. The database isn't running, is empty, or the query failed." >>$LOG
    exit 1
fi
exit 0
# EOF
