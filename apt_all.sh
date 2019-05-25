#!/bin/bash

##Colours
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
BOLD="\033[01;37m"
RESET="\033[0m"

#Exit codes
SUCCESS=0
BAD_LIST_FILE=1	#specified or default file list not readable

TEMP_SUMMARY_FILE="$(dirname "$0")/summary"	#Define the temp file location so that the script will work even if run from a directory without write access
if [ -e ${TEMP_SUMMARY_FILE} ]; then
	rm ${TEMP_SUMMARY_FILE}			# If it exists, delete the temporary file (in case script failed previously before deleting it).
fi

REM_SYS_LIST=${1-"$(dirname $0)/my_hosts.list"}	#First argument is the file name of the list of remote systems.
						#If argument not provided, set default (ball.list in same dir as script).
						#Syntax: parameter=${parameter-default}

#Validate the list of remote systems.
echo
echo "Remote system list is \"${REM_SYS_LIST}\"."
if [ ! -f "${REM_SYS_LIST}" ] || [ ! -r "${REM_SYS_LIST}" ]; then	#If ball.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "${RED}Remote system list \"${REM_SYS_LIST}\" not found, invalid file type or no read access.${RESET}"	#Output error message
	exit ${BAD_LIST_FILE}												#Exit
fi
echo -e "${GREEN}Remote system list \"${REM_SYS_LIST}\" validated.${RESET}"

#Loop through the remote system list.
echo
while read -r REM_SYS <&2; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
				##<&2 needed as descriptor for nested while read loops (while read loop within called script)

	REM_SYS_LENGTH=$(echo "${REM_SYS}" | wc -m)	#Determine the number of characters in host's name (to assist pretty formatting)
	if [ ${REM_SYS_LENGTH} -gt 15 ]			#If the host nmae is a string greater than 10 characters (including end null char)
		then COLUMN_SPACER="\t\t"		#Then long hostname so only want a single tab spacer
		else COLUMN_SPACER="\t\t\t"		#Else short hostname so want two tab spacers.
	fi						#Note formatting as above will keep things neat for host names from 2 to 17 characters (inc. end null)
	echo "${BOLD}║${REM_SYS}${COLUMN_SPACER}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record current system
	echo "----------------------------------------------------------------------------------------------------------"
	echo "Running apt-get commands for ${REM_SYS}"					#Also print current system to stdout.

	REM_HOST=$(echo "${REM_SYS}" | cut -d "@" -f 2)		#Strip the "user@" from the current entry in the hosts file.
	if ! ping -c 1 -W 1 ${REM_HOST} >> /dev/null; then	#Attempt to ping the current host machine.  Ping once (-c 1), wait for 1 second max (-w 1).
		echo "${BOLD}║${RED}System not found.${RESET}\t\t${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record failure.
		echo "${BOLD}║${RESET}Attempting next in list.\t${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record failure.
		echo "${BOLD}╠═══════════════════════════════╣${RESET}" >> $TEMP_SUMMARY_FILE
		continue					#Skip to the next system in the list.
	else
		echo "${BOLD}║${GREEN}System present.${RESET}\t\t${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record success.
		echo "${BOLD}║${RESET}Running apt-get commands:\t${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record success.
	fi

	######Attempt update
	if ! ssh ${REM_SYS} "sudo apt-get -y update"; then				#If attempt failed
		echo "${BOLD}║${RESET}apt-get update\t\t${RED}Failure.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record failure.
		echo "${BOLD}╠═══════════════════════════════╣${RESET}" >> $TEMP_SUMMARY_FILE
		continue								#Skip to the next system in the list.
	else
		echo "${BOLD}║${RESET}apt-get update\t\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE	#Record success
	fi

	######Attempt dist-upgrade
	if ! ssh ${REM_SYS} "sudo apt-get -y dist-upgrade"; then
		echo "${BOLD}║${RESET}apt-get dist-upgrade\t${RED}Failure.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE
		echo "${BOLD}╠═══════════════════════════════╣${RESET}" >> $TEMP_SUMMARY_FILE
		continue
	else
		echo "${BOLD}║${RESET}apt-get dist-upgrade\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE
	fi

	######Attempt autoremove
	if ! ssh ${REM_SYS} "sudo apt-get -y autoremove"; then
		echo "${BOLD}║${RESET}apt-get autoremove\t${RED}Failure.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE
		echo "${BOLD}╠═══════════════════════════════╣${RESET}" >> $TEMP_SUMMARY_FILE
		continue
	else
		echo "${BOLD}║${RESET}apt-get autoremove\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE
	fi

	######Attempt autoclean
	if ! ssh ${REM_SYS} "sudo apt-get -y autoclean"; then
		echo "${BOLD}║${RESET}apt-get autoclean\t${RED}Failure.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE
		echo "${BOLD}╠═══════════════════════════════╣${RESET}" >> $TEMP_SUMMARY_FILE
		continue
	else
		echo "${BOLD}║${RESET}apt-get autoclean\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> $TEMP_SUMMARY_FILE
		echo "${BOLD}╠═══════════════════════════════╣${RESET}" >> $TEMP_SUMMARY_FILE
	fi

done 2< "$REM_SYS_LIST"		##File read by the while loop which includes a list of files to be backed up.
echo "----------------------------------------------------------------------------------------------------------"

#Print out in a pretty format a table indicating the success or failure for each host in the list.
echo
echo -e "${BOLD}╔═Summary:══════════════════════╗${RESET}"
while read -r RESULT ; do
	echo -e ${RESULT}
done < "$TEMP_SUMMARY_FILE"
echo -e "${BOLD}║${RESET}Script complete.\t\t${BOLD}║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════╝${RESET}"
echo

#Delete the temporary file.
rm $TEMP_SUMMARY_FILE

exit $SUCCESS
