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

class BulkLoader:
    def __init__(self, input_file):
        assert isinstance(input_file, str)
        try:
            self.file = open(input_file, r)
        except:
            sys.stderr.write('** error, while attempting to open "{0}"!\n'.format(input_file))
            sys.exit(1)
        for line in self.line:
            print(line)
        

# Displays usage message for the script.
def usage():
    '''Prints usage message to STDOUT.'''
    print('Usage: {0} [-lsx]'.format('duplicate_user.py'))
    print(' -b Bulk load JSON user data from EPLAPP.')
    print(' -x This message.')
    sys.exit(1)

# Take valid command line arguments -b, -s, and -x.
def main(argv):
    customer_loader = ''
    try:
        opts, args = getopt.getopt(argv, "b:x", ['--bulk='])
    except getopt.GetoptError:
        usage()
    for opt, arg in opts:
        if opt in ( "-b", "--bulk_file" ):
             customer_loader = BulkLoader(arg)
        elif opt in "-x":
            usage()
    # Done.
    sys.exit(0)

if __name__ == "__main__":
    # import doctest
    # doctest.testmod()
    main(sys.argv[1:])
    # EOF
