#!/bin/bash
SERVICE=check_dup_user_service.sh
is_running=$(ps aux | egrep elasticsearch | egrep -v grep)
if [[ -z "${is_running// }" ]]; then
	printf "* error: %s not running.\n" $SERVICE >&2
	if ! $HOME/OnlineRegistration/olr-duplicate_user/service.sh start; then
		printf "* error: %s failed to start.\n" $SERVICE >&2
	fi
fi
# EOF
