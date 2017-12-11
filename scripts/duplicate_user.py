#!/usr/bin/env python
###########################################################################
#
# Runs basic functions for the duplicate user database.
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
import sys
import getopt
import urllib3
import json
import re

# curl -i -XGET 'http://localhost:9200/_cluster/health?pretty'
# HTTP/1.1 200 OK
# content-type: application/json; charset=UTF-8
# content-length: 467
# {
  # "cluster_name" : "duplicate_user",
  # "status" : "yellow",     # Fix this by running another node.
  # "timed_out" : false,
  # "number_of_nodes" : 1,
  # "number_of_data_nodes" : 1,
  # "active_primary_shards" : 5,
  # "active_shards" : 5,
  # "relocating_shards" : 0,
  # "initializing_shards" : 0,
  # "unassigned_shards" : 5,
  # "delayed_unassigned_shards" : 0,
  # "number_of_pending_tasks" : 0,
  # "number_of_in_flight_fetch" : 0,
  # "task_max_waiting_in_queue_millis" : 0,
  # "active_shards_percent_as_number" : 50.0
# }

class CustomerFileWriter:
    def __init__(self, output_file_name='users.json'):
        self.output_file = open(output_file_name, 'w')
    
    def _fix_date(self, date_string):
        # If the customer doesn't have a birthdate need to add a dummy one. 
        # Comes in like '0--'
        regex = r"\d{4}\-\d{2}\-\d{2}"
        if re.match(regex, date_string):
            return date_string
        else:
            return '1900-01-01'
            
    def output(self, pipe_data):
        my_data = pipe_data.split('|')
        # UKEY|FNAME|LNAME|EMAIL|DOB|
        # Gets converted into this:
        # {"index":{"_id":"UKEY"}}
        # {"fname":"FNAME", "lname":"LNAME", "dob":"DOB", "email":"EMAIL" }
        index_line = {}
        index_line['index'] = { '_id' : my_data[0] }
        customer   = {}
        customer['fname'] = my_data[1].lower()
        customer['lname'] = my_data[2].lower()
        customer['email'] = my_data[3].lower()
        customer['dob']   = self._fix_date(my_data[4])
        self.output_file.write(json.dumps(index_line) + '\n')
        self.output_file.write(json.dumps(customer) + '\n')        

# Adds users in bulk to the duplicate database.
class BulkAdd:
    def __init__(self, input_file, database, output_file='users.json'):
        assert isinstance(input_file, str)
        self.output_file = output_file
        self.url = 'http://localhost:9200/epl/{0}/_bulk?pretty&pretty'.format(database)
        try:
            self.file = open(input_file, 'r')
        except:
            sys.stderr.write('** error, while attempting to open "{0}"!\n'.format(input_file))
            sys.exit(1)
        customerFileWriter = CustomerFileWriter(self.output_file)
        for line in self.file:
            # Each line is a customer. 
            # UKEY|FNAME|LNAME|EMAIL|DOB|
            customerFileWriter.output(line)  
    def run(self):
        f = open(self.output_file, 'r')
        data = ''
        for line in f:
            data = data + line
        http = urllib3.PoolManager()
        # In examples the 'data' is JSON-ified with json.dumps() but our data is already JSON.
        r = http.request('POST', self.url, body=data, headers={'Content-Type': 'application/json'})
        sys.stderr.write('done.\n')
        # Failed search: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d '{"query":{"match":{"lname":"Bill"}}}'
        # Success search: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?pretty' -d '{"query":{"match":{"lname":"Sexsmith"}}}'
        ####
        # Exact match success: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?q=%2Bfname%3ASusan+%2Blname%3ASexsmith'
        # Exact match fail: curl -i -XGET 'http://localhost:9200/epl/duplicate_user/_search?q=%2Bfname%3ASusan+%2Blname%3ASixsmith'
        ### The '+' means that the condition must be satisfied for the query to succeed. 
        # Page 77 Definitive Guide
        # {"took":3,"timed_out":false,"_shards":{"total":5,"successful":5,"failed":0},"hits":{"total":0,"max_score":null,"hits":[]}}
# Deletes many users from the database based on their user key.
# This class expects the user key to be a single integer value, one-per-line, with no 
# trailing pipe '|' characters.
class BulkDelete:
    def __init__(self, input_file, database, output_file='users.json'):
        assert isinstance(input_file, str)
        self.output_file = output_file
        self.url = 'http://localhost:9200/epl/{0}'.format(database)
        self.user_keys_file = input_file
        
    def run(self):
        http = urllib3.PoolManager()
        try:
            f = open(self.user_keys_file, 'r')
        except:
            sys.stderr.write('** error, while attempting to open "{0}"!\n'.format(self.user_keys_file))
            sys.exit(1)
        for user_key in f:
            # Each line is a customer. 
            # UKEY|
            data = self.url + '/{0}?pretty'.format(user_key.strip())
            print(data)
            r = http.request('DELETE', data, headers={'Content-Type': 'text/plain'})
            print(str(r.data))

# Creates a new epl duplicate_users database with properties.
def create_index(database):
    # Create properties for the index.
    props = {}
    props['settings'] = {}
    props['settings']['index'] = {}
    props['settings']['index']['analysis'] = {}
    props['settings']['index']['analysis']['analyzer'] = {}
    props['settings']['index']['analysis']['analyzer']['analyzer_keyword'] = {'tokenizer':'keyword', 'filter':'lowercase'}
    
    # Mappings
    props['mappings'] = {}
    props['mappings'][database] = {}
    props['mappings'][database]['properties'] = {}
    props['mappings'][database]['properties']['fname'] = {}
    props['mappings'][database]['properties']['fname']['type'] = 'string'
    props['mappings'][database]['properties']['fname']['analyzer'] = 'analyzer_keyword' # Don't parse or treat special
    props['mappings'][database]['properties']['lname'] = {}
    props['mappings'][database]['properties']['lname']['type'] = 'string'
    props['mappings'][database]['properties']['lname']['analyzer'] = 'analyzer_keyword'
    props['mappings'][database]['properties']['email'] = {}
    props['mappings'][database]['properties']['email']['type'] = 'string'
    props['mappings'][database]['properties']['email']['analyzer'] = 'analyzer_keyword'
    props['mappings'][database]['properties']['dob'] = {}
    props['mappings'][database]['properties']['dob']['type'] = 'date'
    json_data = json.dumps(props)
    print(json_data)
    http = urllib3.PoolManager()
    data = 'http://localhost:9200/epl'
    sys.stderr.write('creating index "{0}"\n'.format(data))
    r = http.request('PUT', data, body=json_data, headers={'Content-Type': 'application/json'})
    print(str(r.data))
    
# Deletes the epl index.
def delete_index():
    http = urllib3.PoolManager()
    data = 'http://localhost:9200/epl'
    sys.stderr.write('deleting index "{0}"\n'.format(data))
    r = http.request('DELETE', data, headers={'Content-Type': 'text/plain'})
    print(str(r.data))
        
# Displays usage message for the script.
def usage():
    """Prints usage message to STDOUT."""
    print('''\
    Usage: duplicate_user.py [-b<file>] [-d<delete_user_file>] [-txDC]
    -b (--bulk_add=) Bulk load JSON user data from EPLAPP in the following format: UKEY|FNAME|LNAME|EMAIL|DOB|'
    -C Creates the elasticsearch index, then exits. (See -D for deleting the database).
    -d (--bulk_delete=) Bulk delete users from the database. User keys stored in a file; one-per-line.'
    -D Deletes the elasticsearch index, then exits (deletes the entire database).
    -t Switch on test mode and write to the test database.
    -x This message.''')
    sys.exit(1)

# Take valid command line arguments -b, -d, -t, and -x.
def main(argv):
    customer_loader = ''
    customer_file = ''
    database = 'duplicate_user'
    is_test = False
    try:
        opts, args = getopt.getopt(argv, "b:Cd:Dtx", ['--bulk_add=', '--bulk_delete='])
    except getopt.GetoptError:
        usage()
    for opt, arg in opts:
        if opt in ( "-b", "--bulk_add" ):
            customer_file = arg
            customer_loader = BulkAdd(customer_file, database, 'users_add.json')
            customer_loader.run()
        elif opt in ( "-C" ):
            create_index(database)
            sys.exit(0)
        elif opt in ( "-d", "--bulk_delete" ):
            customer_file = arg
            customer_deleter = BulkDelete(customer_file, database, 'users_delete.txt')
            customer_deleter.run()
        elif opt in ( "-D" ):
            delete_index()
            sys.exit(0)
        elif opt in ( "-t" ):
            database = 'duplicate_user_test'
            is_test = True
        elif opt in "-x":
            usage()
    
    # Done.
    sys.exit(0)

if __name__ == "__main__":
    # import doctest
    # doctest.testmod()
    main(sys.argv[1:])
    # EOF
