# Name: getVersions.sh
#
# Description:  Discover all Java, WebLogic, and Fusion apps installed and versions
#
# Assumptions:  Running as user that has full permissions to /u01 and has privs to sudo to run commands as other user (owner of opatch, weblogic)
#
# History
# 1.0 - Initial Version - Jeremy Phillips
# 1.1 - Revise vendor/product order per Brian Bento request; filter final output to unique values - Jeremy Phillips
# 1.2 - Include patch numbers in Fusion; fix case sensitivity of WLS PSU search; filter permission error for WLS ENV
# 1.3 - Ensure paths were found before looping through; fix parsing issue for syntax variation of opatch
#
unset strXMLOutput
#################################################################################################
# Get Java Versions
###################
# Find paths to java from running instances in process stack
strJavaPath=$(ps -ef | grep -Eo '[^ ]*bin/[j]ava')
# Find path to primary java in path
strJavaPath+=$'\n'$(which java)
# Find paths to java in /u01 (filtering out permission denied errors)
strJavaPath+=$'\n'$(find /usr -name java -type f -executable 2>/dev/null)
# Sort and filter to unique, non-empty lines
strJavaPath=$(printf "%s\n" "$strJavaPath"| grep -v -e '^$' | sort -u)
# If found paths to java
if [[ ! -z "${strJavaPath// }" ]]; then
	# Loop through java instances
	while read -r strPath; do
			unset strLoopString
			unset strLoopOutputVersion
			unset strLoopOutputVendor
			# Capture java version info from stderr
			strLoopString="$($strPath -version 2>&1)"
			# Parse out java version
			strLoopOutputVersion="$(expr "$strLoopString" : '.*java version "\([0-9._]*\).*')"
			# Parse out which JVM type it is
			strLoopOutputVendor="$(expr "$strLoopString" : '.*\(HotSpot\|JRockit\|OpenJDK\).*')"
			# If didn't find Type, define as 'Unknown'
			if [[ -z "${strLoopOutputVendor// }" ]]; then
					strLoopOutputVendor="Unknown"
			fi
			# Create loop XML
			strXMLOutput+="$(printf "<Software><Name>Java %s</Name><Vendor>Oracle</Vendor><Version>%s</Version></Software>" "${strLoopOutputVendor}" "${strLoopOutputVersion}")"
	done <<< "$strJavaPath"
fi
	#
#################################################################################################
# Get Fusion Apps and Versions
##############################
#
# Find paths to opatch in /u01 (filtering out permission denied errors) and only lines that have u01
strOpatchPath=$'\n'$(find /u01 -name opatch -type f -executable 2>/dev/null | grep '/u01')
# If found paths to opatch
if [[ ! -z "${strOpatchPath// }" ]]; then
	# Loop through opatch instances
	while read -r strLoopPath; do
			# Skip empty lines
			[[ -z "${strLoopPath// }" ]] && continue
			unset strLoopString
			unset strOpatchOwner
			# Determine who owns opatch
			strOpatchOwner="$(stat -c %U $strLoopPath)"
			# As owner, execute lsinventory
			strLoopString="$(sudo -u $strOpatchOwner -s -- sh -c "$strLoopPath lsinventory 2>/dev/null")"
			# Parse out fusion apps and versions
			strFusionApps="$(printf "$strLoopString" | sed -r -n '/Installed Top-level Products/,/There are [0-9]* product\(?s\)? installed/p' | grep -v 'Installed Top-level Products' | grep -Ev 'There are [0-9]* product\(?s\)? installed in this Oracle Home' )"
			# Parse out patch versions
			strFusionPatches="$(printf "$strLoopString" | sed -n '/Interim patches/,/OPatch succeeded/p' | grep -oE 'Patch\s*[0-9]{3,20}' | grep -oE '[0-9]{3,20}' | tr '\n' ',')"
			while read -r strIndividualApps; do
					# Skip empty lines
					[[ -z "${strIndividualApps// }" ]] && continue
					# Pull version
					strFusionVersion="$(echo $strIndividualApps | grep -oE '[0-9.]{9,}$')"
					# Pull out app version and white space stripped; strip cariable returns
					strFusionApp="$(echo $strIndividualApps | sed -e "s/$strFusionVersion//g" | sed 's/^[ \t]*//;s/[ \t]*$//')"
					# Create XML output
					 strXMLOutput+="$(printf "<Software><Name>%s</Name><Vendor>Oracle</Vendor><Version>%s</Version><Patches>%s</Patches></Software>" "${strFusionApp}" "${strFusionVersion}" "${strFusionPatches%?}")"
			done <<< "$strFusionApps"
	done <<< "$strOpatchPath"
fi
#################################################################################################
# Get Weblogic Versions
#######################
#
# Find paths to weblogic from running instances in process stack; stripping /server from end
strWLSPath=$(ps -ef | sed -n -e 's/.*[w]eblogic.home=\([^ ]*\)\/server.*/\1/p')
# Find paths to weblogic /(using setWLSEnv.sh) in /u01 (filtering out permission denied errors)
strWLSPath+=$'\n'$(find /u01 -name setWLSEnv.sh -type f -executable 2>/dev/null | sed -n -e 's/\/server\/bin\/setWLSEnv.sh// p')
# Sort and filter to unique, non-empty lines
strWLSPath=$(printf "%s\n" "$strWLSPath"| grep -v -e '^$' | sort -u)
# If found paths to setWLSEnv
if [[ ! -z "${strWLSPath// }" ]]; then
	# Loop through weblogic instances
	while read -r strLoopPath; do
			unset strLoopString
			unset strWebLogicOwner
			# Determine who owns the weblogic dir
			strWebLogicOwner="$(stat -c %U $strLoopPath/server/bin/setWLSEnv.sh)"
			# As owner, execute weblogic.version
			strLoopString="$(sudo -u $strWebLogicOwner WL_HOME=$strLoopPath -s -- sh -c ". $strLoopPath/server/bin/setWLSEnv.sh 2>/dev/null;java weblogic.version")"
			# Parse out weblogic versions (can be multiple for each home that's patched)
			for strMatch in "$(echo $strLoopString | grep -oP 'WebLogic Server.{5,50}(Sun|Mon|Tue|Wed|Thu|Fri|Sat)' | sed 's/....$//' | sed ':a;N;$!ba;s/\n/ /g' )"
			do
					# Create XML output
					strXMLOutput+="$(printf "<Software><Name>WebLogic Server</Name><Vendor>Oracle</Vendor><Version>%s</Version></Software>" "${strMatch}")"
			done
			# Create loop XML
	done <<< "$strWLSPath"
fi
#
#################################################################################################
# Strip newlines from output
# Sort and filter to unique values
strXMLOutput=$(printf "%s" "$strXMLOutput"| grep -Po "<Software>.*?</Software>" | sort -u)
# Print final output
printf "%s\n" "$strXMLOutput"


