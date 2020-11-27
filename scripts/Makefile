###########################################################################
#
# Standardizes calls for database management.
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
# Rev:
#          0.0 - Dev.
#
###########################################################################

#REMOTE_SERVER=sirsi@eplapp.library.ualberta.ca
REMOTE_SERVER=sirsi@edpl-t.library.ualberta.ca
REMOTE_DIR=/s/sirsi/Unicorn/EPLwork/cronjobscripts/OnlineRegistration
HOME=/home/ilsadmin
SAMPLE_LAST_RUN=${REMOTE_SERVER}:${REMOTE_DIR}/last.run
SAMPLE_APP=sample_users.sh
LOCAL_DIR=${HOME}/OnlineRegistration/olr-duplicate_user/scripts
PY_APP=${LOCAL_DIR}/duplicate_user.py
LOCAL_LOADER=${LOCAL_DIR}/fetch_new_users.sh
LOCAL_LOAD_DIR=${HOME}/OnlineRegistration/olr-duplicate_user/incoming
.PHONY: delete create test
test:
	curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?q=+%2Blname%3Afontaine+%2Bfname%3Anicole+%2Bdob%3A1984-02-17+%2Bemail%3Avolkswagon_12yahooca'
delete: ${PY_APP}
	python ${PY_APP} -D
create: ${PY_APP}
	python ${PY_APP} -C
rebuild: ${PY_APP}
	# Take a new sample of all users in the ILS
	## delete the last run file. The sample_app will grab all users.
	touch ${LOCAL_LOAD_DIR}/zero.file
	scp ${LOCAL_LOAD_DIR}/zero.file ${REMOTE_SERVER}:${REMOTE_DIR}/last.run
	## Sample app will now gather data from all users.
	ssh ${REMOTE_SERVER} '${REMOTE_DIR}/${SAMPLE_APP}'
	# Wipe out the last.run file from production.
	python ${PY_APP} -D
	# Create the new index.
	python ${PY_APP} -C
	# Now run the local customer loader.
	${LOCAL_LOADER}
