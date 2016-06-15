#!/usr/bin/env python

import traceback
import sys
import os
import stat
import re
import subprocess

class CmdError(Exception):
    pass

def _run_cmd(command):
    ret = subprocess.call(command, shell=True)
    if ret != 0:
        message = "Error running command"
        raise CmdError(message)


def walk_tree(top,filters,callback):
	for f in os.listdir(top):
		pathname = os.path.join(top, f)

		mode = os.stat(pathname).st_mode
		if stat.S_ISDIR(mode):
			walk_tree(pathname, filters,callback)
		elif stat.S_ISREG(mode):
			beMatch = False
			for pattern in filters:
				if re.search(pattern, pathname):
					beMatch = True
					break
			if beMatch :
				callback(pathname)
		else:
			print 'Skipping %s' % pathname


def toBinaryFile(xmlFile):
	fileName = os.path.basename(xmlFile)
	outPath = xmlFile.replace(".xml",".dbb")
	format = ""
	if re.search("skeleton", fileName):
		format="skeleton"
	else:
		format="texture"

	toolPath = os.path.join(os.getcwd(),"DragonBonesTool","DBTool\ OSX")
	command = "%s -f %s -i %s -o %s" % (toolPath,format,xmlFile,outPath)
	_run_cmd(command)

	_run_cmd("rm -f %s" % xmlFile)



def main():
	curDir = os.getcwd()
	armatureFolder = os.path.join(curDir,"../","client","res/armatures")
	print 'armatureFolder %s' % armatureFolder
	walk_tree(armatureFolder,["xml"],toBinaryFile)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        traceback.print_exc()
        sys.exit(1)