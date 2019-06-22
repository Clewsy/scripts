#!/bin/bash

##Colours
RED="\033[02;31m"
GREEN="\033[02;32m"
BOLD="\033[01;37m"
RESET="\033[0m"

#Exit codes
SUCCESS=0		#I guess it worked?
BAD_LIST_FILE=1		#specified or default file list not readable

TEMP_SUMMARY_FILE="$(dirname "$0")/summary"		#Define the temp file location so that the script will work even if run from a directory without write access
if [ -e "${TEMP_SUMMARY_FILE}" ]; then
	rm "${TEMP_SUMMARY_FILE}"			# If it exists, delete the temporary file (in case script failed previously before deleting it).
fi

REM_SYS_LIST=${1-"$(dirname "$0")/my_hosts.list"}	#First argument is the file name of the list of remote systems.
							#If argument not provided, set default (ball.list in same dir as script).
							#Syntax: parameter=${parameter-default}
#Validate the list of remote systems.
echo
echo "Remote system list is \"${REM_SYS_LIST}\"."
if [ ! -f "${REM_SYS_LIST}" ] || [ ! -r "${REM_SYS_LIST}" ]; then	#If ball.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "${RED}Remote system list \"${REM_SYS_LIST}\" not found, invalid file type or no read access.${RESET}"	#Output error message
	exit ${BAD_LIST_FILE}												#Exit
fi
echo -e "${GREEN}Remote system list \"${REM_SYS_LIST}\" validated.${RESET}"	#Tell user the file list looks okay.

#Create a working system list from the original file list but with #comments stripped.
TEMP_REM_SYS_LIST="$(dirname $0)/temp_rem_sys_list"		#Create the temporary file.
while read -r LINE ; do						#Iterate for every line in the system list.
	STRIPPED_LINE="$(echo ${LINE} | cut -d "#" -f 1)"	#Strip the content of the line after (and including) the first '#'.
	if [ ${STRIPPED_LINE} ] ; then				#If there is anything left in the string (i.e. if entire row is NOT a comment)
	  	echo ${STRIPPED_LINE} >> "${TEMP_REM_SYS_LIST}"	#Then copy the stripped line to the temp file.
	fi
done < "${REM_SYS_LIST}"

#Loop through the remote system list.
echo "-----------------------------------------------"
while read -r REM_SYS; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)

	REM_HOST=$(echo "${REM_SYS}" | cut -d "@" -f 2)	#Strip the "user@" from the current entry in the hosts file.
	if [ ${#REM_HOST} -gt 9 ]			#If the host name is a string greater than 9 characters
		then COLUMN_SPACER="\t"			#Then long hostname so only want a single tab spacer
		else COLUMN_SPACER="\t\t"		#Else short hostname so want two tab spacers.
	fi						#Note formatting as above will keep things neat for host names from 1 to 16 characters

	echo -e "Pinging ${REM_HOST}..."		#Print current ping - keep the user updared on progress or stall point.

	if ! ping -c 1 -W 1 "${REM_HOST}" >> /dev/null; then	#Attempt to ping the current host machine.  Ping once (-c 1), wait for 1 second max (-w 1).
		echo "${GREEN}Ping${RESET} ${REM_HOST}${COLUMN_SPACER}${RED}Miss${RESET}" >> "$TEMP_SUMMARY_FILE"	#Record failure.
	else
		echo "${GREEN}Ping${RESET} ${REM_HOST}${COLUMN_SPACER}${GREEN}Pong${RESET}" >> "$TEMP_SUMMARY_FILE"	#Record success.
	fi

done < "${TEMP_REM_SYS_LIST}"		##File read by the while loop which includes a list of files to be backed up.


#Print out in a pretty format a table indicating the success or failure of ppinging each host in the list.
echo
echo -e "${BOLD}╔═════Summary:══════════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}"
done < "${TEMP_SUMMARY_FILE}"
echo -e "${BOLD}╚═══════════════════════════╝${RESET}"
echo

rm "${TEMP_SUMMARY_FILE}"	#Delete the temporary summary file.
rm "${TEMP_REM_SYS_LIST}"	#Delete the temporary system list file.

exit $SUCCESS
