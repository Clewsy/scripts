#!/bin/bash

#This script will take an argument or either a single host, or a list of hosts.
#It will then run apt-get update, apt-get dist-upgrade, apt-get autoremove and then apt-get autoclean on the provided host/s.

##Colours
RED="\033[02;31m"
GREEN="\033[02;32m"
BOLD="\033[01;37m"
RESET="\033[0m"

#Exit codes
SUCCESS=0	#Noice
BAD_USAGE=1	#Incorrect usage

USAGE="
Usage: $(basename $0) [hosts]
Where [hosts] can be:
	- [user@host]
	- [host]	(same user as current)
	- [hosts.list]	(file containing a list of [user@host] or [host]
	- ommitted	(script will look for host.list file of the name \"my_hosts.list\")
"

if [ $# -gt 1 ]; then		#If more than one argument is entered.
	echo -e "${USAGE}"	#Print the usage
	exit ${BAD_USAGE}	#Exit
fi

ARGUMENT=${1-"$(dirname "$0")/my_hosts.list"}	#First argument is the file name of the list of remote systems.
						#If argument not provided, set default (ball.list in same dir as script).
						#Syntax: parameter=${parameter-default}

TEMP_SUMMARY_FILE="$(dirname "$0")/summary"		#Define temp file location so the script will work even if run from a directory without write access
if [ -e "${TEMP_SUMMARY_FILE}" ]; then rm "${TEMP_SUMMARY_FILE}"; fi	#If it exists, delete the temporary file (in case script failed previously).

TEMP_REM_SYS_LIST="$(dirname $0)/temp_rem_sys_list"	#Define a working system list
if [ -e "${TEMP_REM_SYS_LIST}" ]; then rm "${TEMP_REM_SYS_LIST}"; fi	#If it exists, delete the temporary file (in case script failed previously).

echo
if [ ! -f "${ARGUMENT}" ] || [ ! -r "${ARGUMENT}" ]; then	#If list file is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "Remote system is \"${ARGUMENT}\""		#Then assume provided argument is a single host (either [host] or [user@host])
	echo "${ARGUMENT}" > "${TEMP_REM_SYS_LIST}"		#Create the temp list file which will just contain the single entry.
else
	echo -e "Remote system list \"${ARGUMENT}\" validated.${RESET}"	#Tell the user the list looks okay
	while read -r LINE ; do						#Iterate for every line in the system list.
		STRIPPED_LINE="$(echo ${LINE} | cut -d "#" -f 1)"	#Strip the content of the line after (and including) the first '#'.
		if [ ${STRIPPED_LINE} ] ; then				#If there is anything left in the string (i.e. if entire row is NOT a comment)
	  		echo ${STRIPPED_LINE} >> "${TEMP_REM_SYS_LIST}"	#Then copy the stripped line to the temp file.
		fi
	done < "${ARGUMENT}"
fi

#Loop through the remote system list.
echo
while read -r REM_SYS <&2; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
				##<&2 needed as descriptor for nested while read loops (while read loop within called script)

	if [ ${#REM_SYS} -gt 6 ]; then
		if [ ${#REM_SYS} -gt 14 ]; then		#If the host name is a string greater than 14 characters
			COLUMN_SPACER="\t\t"	#Then long hostname so only want a single tab spacer
		else
		       	COLUMN_SPACER="\t\t\t"	#Else short hostname so want two tab spacers.
		fi
	else
		COLUMN_SPACER="\t\t\t\t"
	fi
	echo "${BOLD}║${REM_SYS}${COLUMN_SPACER}║${RESET}" >> "${TEMP_SUMMARY_FILE}"	#Record current system
	echo "------------------------------------------------------"
	echo "Running apt-get commands for ${REM_SYS}"					#Also print current system to stdout.

	REM_HOST=$(echo "${REM_SYS}" | cut -d "@" -f 2)		#Strip the "user@" from the current entry in the hosts file.
	if ! ping -c 1 -W 1 "${REM_HOST}" >> /dev/null; then	#Attempt to ping the current host machine.  Ping once (-c 1), wait for 1 second max (-w 1).
		{
			echo -E "${BOLD}║${RED}System not found.${RESET}\t\t${BOLD}║${RESET}"
			echo -E "${BOLD}║${RESET}Attempting next in list.\t${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record failure
		continue			#Skip to the next system in the list.
	else
		{
			echo -E "${BOLD}║${GREEN}System present.${RESET}\t\t${BOLD}║${RESET}"
			echo -E "${BOLD}║${RESET}Running apt-get commands:\t${BOLD}║${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record success.
	fi

	######Attempt update
	if ! ssh "${REM_SYS}" "sudo apt-get -y update"; then	#If attempt failed
		{
			echo -E "${BOLD}║${RESET}apt-get --show-progress update\t\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record failure
		continue			#Skip to the next system in the list.
	else
		echo -E "${BOLD}║${RESET}apt-get update\t\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> "${TEMP_SUMMARY_FILE}"		#Record success
	fi

	######Attempt dist-upgrade
	if ! ssh "${REM_SYS}" "sudo apt-get -y --show-progress dist-upgrade"; then
		{
			echo -E "${BOLD}║${RESET}apt-get dist-upgrade\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record failure
		continue			#Skip to the next system in the list.
	else
		echo -E "${BOLD}║${RESET}apt-get dist-upgrade\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> "${TEMP_SUMMARY_FILE}"	#Record success
	fi

	######Attempt autoremove
	if ! ssh "${REM_SYS}" "sudo apt-get -y --show-progress autoremove"; then
		{
			echo -E "${BOLD}║${RESET}apt-get autoremove\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record failure
		continue			#Skip to the next system in the list.
	else
		echo -E "${BOLD}║${RESET}apt-get autoremove\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> "${TEMP_SUMMARY_FILE}"	#Record success
	fi

	######Attempt autoclean
	if ! ssh "${REM_SYS}" "sudo apt-get -y autoclean"; then
		{
			echo -E "${BOLD}║${RESET}apt-get autoclean\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record failure
		continue			#Skip to the next system in the list.
	else
		{
			echo -E "${BOLD}║${RESET}apt-get autoclean\t${GREEN}Success.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	#Record success
	fi

done 2< "${TEMP_REM_SYS_LIST}"		##File read by the while loop which includes a list of files to be backed up.
echo "------------------------------------------------------"

#Print out in a pretty format a table indicating the success or failure for each host in the list.
echo
echo -e "${BOLD}╔═Summary:══════════════════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${RESULT}"
done < "${TEMP_SUMMARY_FILE}"
echo -e "${BOLD}║${RESET}Script complete.\t\t${BOLD}║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════╝${RESET}"
echo

rm "${TEMP_SUMMARY_FILE}"	#Delete the temporary summary file.
rm "${TEMP_REM_SYS_LIST}"	#Delete the temporary system list file.

exit ${SUCCESS}
