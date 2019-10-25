#!/bin/bash
##################################################################################
#
# Bash shell script for starting and stopping the duplicate elastic search database.
#
# Fetch the set of new users from the ILS, then zero out the file on success.
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
# Copyright (c) Wed Feb 22 16:51:17 MST 2017
# Rev:
#          0.0 - Dev.
#
##############################################################################
### This script copies the new users' data from the ILS. The
# Setup variables
[[ -z "${DEPLOY_ENV}" ]] && DEPLOY_ENV='dev'
if [[ "$DEPLOY_ENV" == "prod" ]]; then
  SERVER=sirsi@eplapp.library.ualberta.ca
else
  SERVER=sirsi@edpl-t.library.ualberta.ca
fi
echo "Connecting to $SERVER"
USER_FILE=users.lst
REMOTE_DIR=/s/sirsi/Unicorn/EPLwork/cronjobscripts/OnlineRegistration
LOCAL_DIR=$HOME/OnlineRegistration/olr-duplicate_user/incoming
PY_SCRIPT_DIR=$HOME/OnlineRegistration/olr-duplicate_user/scripts/duplicate_user.py
PY_SCRIPT_ARGS="-b$USER_FILE"
cd $LOCAL_DIR
scp $SERVER:$REMOTE_DIR/$USER_FILE $USER_FILE
if [ -s "$USER_FILE" ]; then
	/usr/bin/python $PY_SCRIPT_DIR $PY_SCRIPT_ARGS
	# Zero out the remote file to ensure we don't reload the users.
	touch zero.file
	scp zero.file $SERVER:$REMOTE_DIR/$USER_FILE
	exit 0
else
	printf "* warn: file '%s' didn't copy over from %s.\n" $USER_FILE $SERVER >&2
	exit 1
fi
# EOF
