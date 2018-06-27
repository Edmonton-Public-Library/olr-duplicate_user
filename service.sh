#!/bin/bash
##################################################################################
#
# Bash shell script for starting and stopping the duplicate elastic search database. 
#
# Identify and if possible fix a broken hold that causes item database errors.
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
# Copyright (c) Thu Feb  9 16:30:09 MST 2017
# Rev: 
#          0.0 - Dev. 
#
##############################################################################
# Setup variables
SERVICE="duplicate user elasticsearch instance."
# PORT=9200
ELASTIC_BIN=/home/ilsadmin/duplicate_user/elasticsearch-5.2.0/bin/elasticsearch
PID_FILE=/home/ilsadmin/duplicate_user/elasticsearch.pid
do_exec()
{
	if [ ! -f "$ELASTIC_BIN" ]; then
		printf "** failed to find %s\n" "$ELASTIC_BIN" >&2
		return 1
	fi
    if [[ "$1" == "-start" ]]; then
		$ELASTIC_BIN -p "$PID_FILE" -d
		return 0
	elif [[ "$1" == "-stop" ]]; then
		pid=$(cat $PID_FILE)
		# 15516
		kill -SIGTERM $pid
		return 0
	elif [[ "$1" == "-check" ]]; then
		is_running=$(ps aux | grep elasticsearch | egrep -v grep)
		if [[ -z "${is_running// }" ]]; then
			printf "* error: %s not running.\n" "$SERVICE" >&2
			return 1
		fi
	else
		# Do the, whoa, wait, what now?
		return 1
	fi
}

case "$1" in
    start)
        if ! do_exec "-start"; then
			printf "* failed to start %s.\n" "$SERVICE" >&2
			exit 1
		else
			exit 0
		fi
        ;;
    stop)
        if ! do_exec "-stop"; then
			printf "* failed to stop %s.\n" "$SERVICE" >&2
			exit 1
		else
			exit 0
		fi
        ;;
    restart)
		if ! do_exec "-stop"; then
			printf "* failed to stop %s.\n" "$SERVICE" >&2
			exit 1
		fi
		if ! do_exec; then
			printf "* failed to start %s.\n" "$SERVICE" >&2
			exit 1
		else
			exit 0
		fi
        ;;
	check)
		if ! do_exec "-check"; then
			printf "* failed to stop %s.\n" "$SERVICE" >&2
			exit 1
		else
			printf "OK.\n" >&2
			curl -XGET 'http://localhost:9200/_cluster/health?pretty'
			curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_count?pretty' -d '{"query": {"match_all": {}}}'
		fi
		;;
    *)
        printf "usage: $0 {start|check|stop|restart}\n\n" >&2
        exit 3
        ;;
esac
# EOF
