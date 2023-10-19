#!/usr/bin/env python

# Copyright (c) 2015 ARM Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""This script will merge two hex files and write the output to a hex file.
   USAGE: merge_hex.py input_file1 input_file2 output_file.
"""

from optparse import OptionParser
import sys

parser = OptionParser()

#command line options
parser.add_option("-o", "--output",
                  action="store",
	              type="string",
                  dest="output",
                  default="",
                  help="The relative path to the headers for the microbit-dal.")

(options, args) = parser.parse_args()

fail_color = ''

# If colorama is present, set the fail color to red
try:
    from colorama import init, deinit, Fore
    fail_color = Fore.RED
except:
    pass

def fail(message):
    print(fail_color + message)

    # If we've included ANSI color in output, reset the output style
    if fail_color:
        print(Fore.RESET)
        deinit()

    return 1

def convert_start_addr(hex_file):
    if hex_file.start_addr and 'CS' in hex_file.start_addr:
        start_addr = {'EIP': (hex_file.start_addr['CS'] * 16) + hex_file.start_addr['IP']}
        hex_file.start_addr = start_addr

def main(options, args):
    # If using ANSI coloring is available, initialize colorama
    if fail_color:
        init()

    # Import intelhex if avaialable, otherwise fail
    try:
        from intelhex import IntelHex
    except:
        return fail('error: You do not have \'intelhex\' installed. Please run \'pip install intelhex\' then retry.')

    if len(options.output) is 0:
        print "No output file specified"
        exit(1)

    if len(args) < 2:
        return fail('Only one file was provided to merge.')
        exit(0)

    # Get the two hex files, merge them, and save the result
    orig = IntelHex(args[0])
    convert_start_addr(orig)

    args = args[1:]

    for arg in args:
        other = IntelHex(arg)
        convert_start_addr(other)
        orig.merge(other, overlap='replace')

    orig.write_hex_file(options.output)

if __name__ == '__main__':
    sys.exit(main(options,args))
