# findOHS.py
import os
import pwd
import subprocess

# List all paths to search
searchPaths = [
  '/u01',
  '/etc/'
  ]
opatchList = []

# search all paths for opatch
 16 for searchPath in searchPaths:
 17   print "searchPaths: %s" % searchPaths
 18   for root, dirs, files in os.walk(searchPath):
 19     # Filter out NFS mounts
 20     dirs[:] = filter(lambda dir: not os.path.ismount(os.path.join(root, dir)), dirs)
 21     for file in files:
 22       if file == 'opatch':
 23         opatchList.append(os.path.join(root, file))
 24         print "FOUND opatch: %s" % os.path.join(root, file)
 25
 26 print '*************************************'
 27 print '***** query each opatch'
 28 print '*************************************'
 29 # Loop through opatch
 30 for opatch in opatchList:
 31   print "opatch: %s" % opatch
 32   # find who owner is
 33   opatchOwner = pwd.getpwuid(os.stat(opatch).st_uid).pw_name
 34   # print "opatch owner: **%s**" % opatchOwner
 35   # as owner of opatch, execute lsinventory
 36   result = subprocess.Popen(['/usr/bin/sudo', '-u', opatchOwner, '-s', '--', '/bin/sh', '-c', '""' + opatch + ' lsinventory 2>/dev/null""'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
 37   output, err = result.communicate("input data that is passed to subprocess' stdin")
 38
 39   # print "opatch output: %s" % output
 40   # print "opatch error: %s" % err
 41
 42  # Parse out top level products section
 43   # productsTop = re.search('Installed Top-level Products.*There are [0-9]* products installed in this Oracle Home', output, re.MULTILINE)
 44   print "Type: %s" % type(output)
 45   productsTop = re.search('Installed Top-level Products.*There are [0-9]* products installed in this Oracle Home', output, re.DOTALL)
 46
 47   if productsTop is None:
 48     print "Top level not found!"
 49   else:
 50     print "Top Level: %s" % productsTop.group(0)
 51
 52     #Remember num of products to find
 53     productCount = re.search('Installed Top-level Products \(([0-9]*)\):', productsTop.group(0))
 54     print "Found count: %s" % productCount.group(1)
 55     # Parse out top level products
 56     productsTopList = re.search('.* [0-9]*.[0-9]*.[0-9]*.[0-9]*.[0-9]*', productsTop.group(0))
 57     for productTop in productsTopList:
 58       print "productTop: %s" % productTop
 59
 60
