#!/bin/bash
is_running=$(ps aux | egrep elasticsearch | egrep -v egrep)
if [[ -z "${is_running// }" ]]; then
	printf "* error: %s not running.\n" "$SERVICE" >&2
	/home/ilsadmin/duplicate_user/service.sh start
fi    
# EOF
