#!/usr/bin/env python3

# bump_build_nr.py
# Bumps build version to an APP_VERSION file containing hard-coded SemVer 2.0 struct definition:
# Ido Rabin @ Sept 2022
# python3

import fileinput
from subprocess import check_output
import re
import sys
import os
from os import path, makedirs
import fileinput
from tempfile import NamedTemporaryFile


FILEPATH = '/Users/syncme/vapor/bricks_server/Sources/App/AppVersion.swift'
print(f'= bump_build_nr.py is starting: =')

if not os.path.isfile(FILEPATH):
	print(f'❌ bump_build_nr.py failed finding FILEPATH - please correct the path: {FILEPATH}')

def incrementLastInt(input, contains, addInt):
    # will either return the same line it recieved, or change the line if it contains the contains string, looking for an int to increase by addInt amount
	result = input
	arr = input.split(contains)
	if len(arr) > 1:
		result = arr[0] + contains + f'{int(arr[1]) + int(addInt)}\n'
	return result

# open Version file
temp_file_name = ''
with open(FILEPATH, mode='r+', encoding='utf-8') as f:
	with NamedTemporaryFile(delete=False, mode='w+', encoding='utf-8') as fout:
		temp_file_name = fout.name
		for line in f:
			line = incrementLastInt(line, 'BUILD: Int = ', +1)
			fout.write(line)

os.rename(temp_file_name, FILEPATH)
print(f'✅  {FILEPATH} was successfully updated')
