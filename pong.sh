#!/bin/bash

##Colours
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
BLUE="\033[00;34m"
BLACK="\033[00;30m"
BOLD="\033[01;37m"
RESET="\033[0m"

#Exit codes
SUCCESS=0
BAD_LIST_FILE=1	#specified or default file list not readable

TEMP_SUMMARY_FILE="$(dirname "$0")/summary"	#Define the temp file location so that the script will work even if run from a directory without write access
rm $TEMP_SUMMARY_FILE				#Delete the temporary file (in case script failed previously before deleting it).

REM_SYS_LIST=${1-"$(dirname $0)/my_hosts.list"}	#First argument is the file name of the list of remote systems.
						#If argument not provided, set default (ball.list in same dir as script).
						#Syntax: parameter=${parameter-default}

#Validate the list of remote systems.
echo
echo "Remote system list is \"$REM_SYS_LIST\"."
if [ ! -f "$REM_SYS_LIST" ] || [ ! -r "$REM_SYS_LIST" ]; then	#If ball.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "${RED}Remote system list \"$REM_SYS_LIST\" not found, invalid file type or no read access.${RESET}"	#Output error message
	exit $BAD_LIST_FILE												#Exit
fi
echo -e "${GREEN}Remote system list \"$REM_SYS_LIST\" validated.${RESET}"

#Loop through the remote system list.
echo
echo "----------------------------------------------------------------------------------------------------------"
while read -r REM_SYS <&2; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
				##<&2 needed as descriptor for nested while read loops (while read loop within called script)

	#Strip the "user@" from the current entry in the hosts file.
	REM_HOST=$(echo "${REM_SYS}" | cut -d "@" -f 2)
	echo -e "Pinging ${REM_HOST}..."

	if ! ping -c 1 -W 1 $REM_HOST >> /dev/null; then	#Attempt to ping the current host machine.
		echo "${GREEN}Ping${BLACK}--------${RESET}$REM_HOST\t${BLACK}--------${RED}Miss${RESET}" >> $TEMP_SUMMARY_FILE		#Record failure.
	else
		echo "${GREEN}Ping${BLACK}--------${RESET}$REM_HOST\t${BLACK}--------${GREEN}Pong${RESET}" >> $TEMP_SUMMARY_FILE	#Record success.
	fi

done 2< "$REM_SYS_LIST"		##File read by the while loop which includes a list of files to be backed up.


#Print out in a pretty format a table indicating the success or failure for each host in the list.
echo
echo -e "${BOLD}╔═══Summary:════════════════════════╗${RESET}"
while read -r RESULT ; do
	echo -e ${BOLD}║${RESET}${RESULT}${BOLD}║${RESET} | column
done < "$TEMP_SUMMARY_FILE"
echo -e "${BOLD}╚═══════════════════════════════════╝${RESET}"
echo

#Delete the temporary file.
rm $TEMP_SUMMARY_FILE

exit $SUCCESS
