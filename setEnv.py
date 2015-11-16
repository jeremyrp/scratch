#!/usr/bin/python
################################################
### Name: setEnv.py
### Desc: Set environment
################################################

# Pre-Requisites
# PowerSHell
# Set-ExecutionPolicy Unrestricted
# pip install virtualenv --proxy http://www-proxy.us.oracle.com
# pip install MapGitConfig virtualenv --proxy http://www-proxy.us.oracle.com

import sys
import gitconfig

if len(sys.argv) != 1:
  print "setEnv.py requires a single argument to denote environment."
  print "Supported env:  Home, Oracle, Public"
  exit

### Environment Settings
envSettings = {}
envSettings['home'] = {}
envSettings['home']['proxy'] = ''
envSettings['home'] = {}
envSettings['oracle']['proxy'] = 'http://www-proxy.us.oracle.com:80'
envSettings['public'] = {}
envSettings['home']['proxy'] = ''

envLocation = sys.arg[0].lowercase

### Set proxy
#####################################
### in env
myGit = gitconfig.GetConfig('global')
config['http.proxy'] = envSettings[envLocation]['proxy']
