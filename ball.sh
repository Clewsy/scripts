#!/bin/bash

##Colours
RED="\033[02;31m"
GREEN="\033[02;32m"
BOLD="\033[01;37m"
RESET="\033[0m"

#Exit codes
SUCCESS=0	#Toight
BAD_LIST_FILE=1	#Specified or default list file not readable

TEMP_BALL_SUMMARY="$(dirname "$0")/temp_ball_summary"	#Define the temp file location so that the script will work even if run from a directory without write access
if [ -e "${}" ]; then
	rm "${TEMP_BALL_SUMMARY}"			#If it exists, delete the temporary file (in case script failed previously before deleting it).
fi

REM_SYS_LIST=${1-"$(dirname "$0")/my_hosts.list"}	#First argument is the file name of the list of remote systems.
							#If argument not provided, set default (ball.list in same dir as script).
							#Syntax: parameter=${parameter-default}

#Validate the list of remote systems.
echo "Remote system list is \"{$REM_SYS_LIST}\"."
if [ ! -f "${REM_SYS_LIST}" ] || [ ! -r "${REM_SYS_LIST}" ]; then	#If ball.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "${RED}Remote system list \"${REM_SYS_LIST}\" not found, invalid file type or no read access.${RESET}"	#Output error message
	exit "${BAD_LIST_FILE}"												#Exit
fi
echo -e "${GREEN}Remote system list \"${REM_SYS_LIST}\" validated.${RESET}"

#Create a working system list from the original file list but with #comments stripped.
TEMP_REM_SYS_LIST="$(dirname $0)/temp_rem_sys_list"		#Create the temporary file.
while read -r LINE ; do						#Iterate for every line in the system list.
	STRIPPED_LINE="$(echo ${LINE} | cut -d "#" -f 1)"	#Strip the content of the line after (and including) the first '#'.
	if [ ${STRIPPED_LINE} ] ; then				#If there is anything left in the string (i.e. if entire row is NOT a comment)
	  	echo ${STRIPPED_LINE} >> "${TEMP_REM_SYS_LIST}"	#Then copy the stripped line to the temp file.
	fi
done < "${REM_SYS_LIST}"

#Loop through the remote system list.
echo
echo -e "--------------------------------------------------------------------"
while read -r REM_SYS <&2; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
				##<&2 needed as descriptor for nested while read loops (while read loop within called script)

	echo -e "Attempting backup for \"${REM_SYS}\""
	if ! ssh -t "${REM_SYS}" "~/bin/bu.sh"; then					#Attempt to connect via ssh and run the backup script "bu.sh"
		echo -E "${REM_SYS}\t ${RED}Failure.${RESET}" >> ${TEMP_BALL_SUMMARY}	#If the above fails for the current host, record the failure
		continue								# then try the next host in the list.
	else
		echo -E "${REM_SYS}\t ${GREEN}Success.${RESET}" >> ${TEMP_BALL_SUMMARY}	#If the above succeeds, record the success.
											#Note a "success" means the ssh session was created and exited
											# gracefully.  Failures with the called script are not checcked.
	fi
	echo "--------------------------------------------------------------------"

done 2< "${TEMP_REM_SYS_LIST}"		##File read by the while loop which includes a list of files to be backed up.

#Print out in a pretty format a table indicating the success or failure for each host in the list.
echo
echo -e "${BOLD}╔════════Summary:════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}"
done < "${TEMP_BALL_SUMMARY}"
echo -e "${BOLD}╚════════════════════════╝${RESET}"
echo

rm "${TEMP_BALL_SUMMARY}"	#Delete the temporary summary file.
rm "${TEMP_REM_SYS_LIST}"	#Delete the temporary system list file.

exit ${SUCCESS}
