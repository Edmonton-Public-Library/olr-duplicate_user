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

# curl -i -XGET 'http://localhost:9200/_cluster/health?pretty'
# HTTP/1.1 200 OK
# content-type: application/json; charset=UTF-8
# content-length: 467
# {
  # "cluster_name" : "duplicate_user",
  # "status" : "yellow",
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
    
    def output(self, pipe_data):
        my_data = pipe_data.split('|')
        # UKEY|FNAME|LNAME|EMAIL|DOB|
        # 1382679|LEVI|PETER|LPETER946@MYNORQUEST.CA|19940101|
        # Gets converted into this:
        # {"index":{"_id":"UKEY"}}
        # {"fname":"FNAME", "lname":"LNAME", "dob":"DOB", "email":"EMAIL" }
        self.output_file.write("{\"index\":{\"_id\": \"%s\"}}\n{" % (my_data[0]))
        self.output_file.write("\"fname\": \"%s\", " % (my_data[1]))
        self.output_file.write("\"lname\": \"%s\", " % (my_data[2]))
        self.output_file.write("\"email\": \"%s\", " % (my_data[3]))
        self.output_file.write("\"dob\": \"%s\" }\n" % (my_data[4]))

class BulkLoader:
    def __init__(self, input_file, output_file='users.json'):
        assert isinstance(input_file, str)
        try:
            self.file = open(input_file, 'r')
        except:
            sys.stderr.write('** error, while attempting to open "{0}"!\n'.format(input_file))
            sys.exit(1)
        customerFileWriter = CustomerFileWriter(output_file)
        for line in self.file:
            # Each line is a customer. 
            # UKEY|FNAME|LNAME|EMAIL|DOB|
            customerFileWriter.output(line)  
    def load(self, url, data_file='users.json'):
        f = open(data_file, 'r')
        data = ''
        for line in f:
            data = data + line
            print(line)
        http = urllib3.PoolManager()
        # In examples the 'data' is JSON-ified with json.dumps() but our data is already JSON.
        r = http.request('POST', url, body=data, headers={'Content-Type': 'application/json'})
        # Failed search: curl -i -XGET 'http://localhost:9200/epl/duplicate_user_test/_search?pretty' -d '{"query":{"match":{"lname":"Bill"}}}'
        # Success search: curl -i -XGET 'http://localhost:9200/epl/duplicate_user_test/_search?pretty' -d '{"query":{"match":{"lname":"Sexsmith"}}}'

# Displays usage message for the script.
def usage():
    '''Prints usage message to STDOUT.'''
    print('Usage: {0} [-lsx]'.format('duplicate_user.py'))
    print(' -b Bulk load JSON user data from EPLAPP.')
    print(' -x This message.')
    sys.exit(1)

# Take valid command line arguments -b, -U, and -x.
def main(argv):
    customer_loader = ''
    customer_file = ''
    bulk_url = 'http://localhost:9200/epl/duplicate_user_test/_bulk?pretty&pretty'
    try:
        opts, args = getopt.getopt(argv, "b:Ux", ['--bulk='])
    except getopt.GetoptError:
        usage()
    for opt, arg in opts:
        if opt in ( "-b", "--bulk_file" ):
            customer_file = arg
        elif opt in "-U":
            pass
        elif opt in "-x":
            usage()
    customer_loader = BulkLoader(customer_file, 'users.json')
    customer_loader.load(bulk_url, 'users.json')
    # Done.
    sys.exit(0)

if __name__ == "__main__":
    # import doctest
    # doctest.testmod()
    main(sys.argv[1:])
    # EOF
