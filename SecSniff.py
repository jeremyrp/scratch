#!/usr/bin/env python
import os
import re
import string
import subprocess

#################################################################################################
# Functions
###################
def find_all_files(name,path):
  result = []
  for root, dirs, files in os.walk(path):
    if name in files:
      result.append(os.path.join(root, name))
  return result



#################################################################################################
# Get Java Versions
###################

### Find paths to java from running instances in process stack


### Initialize list of java executables
javaBins = []

### Capture all current running processes
pids = [pid for pid in os.listdir('/proc') if pid.isdigit()]

### Loop through each process
for pid in pids:
  try:
    ### Print PID
    # print "PID: %s" % pid
    ### Find command line for process
    strPScmdline = open(os.path.join('/proc', pid, 'cmdline'), 'rb').read()
    ### Replace null (\0) with space
    # strPScmdline = strPScmdline.replace('\x00',' ')

    ### If process is running a /bin/java
    if re.search('[^ ]*bin/[j]ava',strPScmdline) is not None:
      ### Strip all parameters after path to /bin/java
      strPScmdline = strPScmdline.split('\x00')[0]

      ### Add command line to array of java to check versions
      javaBins.append(strPScmdline)

    #### Print out command line path
    # print "CMD: %s" % strPScmdline
    # print "Type: %s" % type(strPScmdline)

  except IOError: # proc has already terminated
    continue

### Find java executables in /u01
# javaBins.(find_all_files('java','/u01'))

### Sort and filter unique from list of java executables
javaBins = sorted(set(javaBins))

for javaBin in javaBins:
  try:
    #print javaBin
    ### Get the version info from java
    batcmd = javaBin + ' --version'
    result = subprocess.Popen([javaBin,'-version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = result.communicate()

    ### Parse out the version number
    javaVersion = re.search('.*java version "\([0-9._]*\).*',err)


    print "Result: %s" % err
  except IOError:
    continue

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
