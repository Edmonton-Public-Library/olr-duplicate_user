#! /bin/bash
########################################################################
#
# Query if a user appears in the duplicate database.
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
#          0.2 - Add intransit information with -i.
#          0.1 - Dev.
#
########################################################################
FIRST_NAME=''                  # Customer first name.
LAST_NAME=''                   # Customer last name.
DOB=''                         # Customer DOB.
EMAIL=''                       # Customer email.
###############
# Display usage message.
# param:  none
# return: none
usage()
{
    printf "Usage: %s [-option]\n" "$0" >&2
    printf " Reports users in the duplicate database by different criteria.\n" >&2
    printf "   -d'yyyy-mm-dd' Date of birth.\n" >&2
    printf "   -e'email@address' - Customers email address.\n" >&2
    printf "   -f'firstname' Search by the customer's first name.\n" >&2
    printf "   -l'lastname' Search by the customer's last name.\n" >&2
    printf "   -x This message.\n" >&2
    printf "\n" >&2
    printf "   Version: %s\n" $VERSION >&2
    exit 1
}


while getopts ":d:e:f:l:x" opt; do
case $opt in
    d) DOB=$OPTARG
        ;;
    e) EMAIL=$OPTARG
        ;;
    f) FIRST_NAME=$OPTARG
        ;;
    l) LAST_NAME=$OPTARG
        echo "\$LAST_NAME = $LAST_NAME" >&2
        ;;
    x) usage
        ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        usage
        exit 1
        ;;
    :) echo "Option -$OPTARG requires an argument." >&2
        usage
        exit 1
        ;;
esac

# Failed search: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d '{"query":{"match":{"lname":"Bill"}}}'
# Success search: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d '{"query":{"match":{"lname":"Sexsmith"}}}'
####
# Exact match success: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?q=%2Bfname%3ASusan+%2Blname%3ASexsmith'
# Exact match fail: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?q=%2Bfname%3ASusan+%2Blname%3ASixsmith'
### The '+' means that the condition must be satisfied for the query to succeed.
# Page 77 Definitive Guide
# {"took":3,"timed_out":false,"_shards":{"total":5,"successful":5,"failed":0},"hits":{"total":0,"max_score":null,"hits":[]}}
done
if [ -n "$LAST_NAME" ]; then
    curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d "{\"query\":{\"match\":{\"lname\":\""$LAST_NAME"\"}}}"
elif [ -n "$FIRST_NAME" ]; then
    curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d "{\"query\":{\"match\":{\"fname\":\""$FIRST_NAME"\"}}}"
elif [ -n "$EMAIL" ]; then
    curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d "{\"query\":{\"match\":{\"email\":\""$EMAIL"\"}}}"
elif [ -n "$DOB" ]; then
    curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d "{\"query\":{\"match\":{\"dob\":\""$DOB"\"}}}"
else
    usage
    exit 1
fi
# SEARCH_STRING=''
# if [ -n "$LAST_NAME" ]; then
    # curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d "{\"query\":{\"match\":{\"lname\":\""$LAST_NAME"\"}}}"
    # SEARCH_STRING=$SEARCH_STRING"%2Blname%3$LAST_NAME"
# elif [ -n "$FIRST_NAME" ]; then
    # SEARCH_STRING=$SEARCH_STRING"+%2Bfname%3A$FIRST_NAME"
    # SEARCH_STRING=$SEARCH_STRING"%2Bfname%3A$FIRST_NAME+%2Blname%3ASexsmith"
# elif [ -n "$EMAIL" ]; then
    # SEARCH_STRING=$SEARCH_STRING"+%2Bemail%3$EMAIL"
# elif [ -n "$DOB" ]; then
    # SEARCH_STRING=$SEARCH_STRING"+%2Bdob%3$DOB"
# else
    # usage
    # exit 1
# fi
# curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d "{\"query\":{\"match\":{\"lname\":\""$LAST_NAME"\"}}}"
# echo "\$SEARCH_STRING='$SEARCH_STRING'"
# curl -i -XGET "http://localhost:9200/epl/duplicate_user/_search?q=${SEARCH_STRING}"
# EOF
