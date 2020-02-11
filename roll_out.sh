#!/bin/bash

##This script will attempt to copy a specified file to a destination (relative to home directory) on a list of remote hosts.

##########Colours.
RED="\033[02;31m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
BOLD="\033[01;37m"
RESET="\033[0m"

##########Exit codes
SUCCESS=0	#Noice.
BAD_USAGE=1	#Incorrect usage.
BAD_HOST=2	#Ping to specified host failed.

#########Usage
USAGE="
$(basename "$0") is used to copy a specified file to the home directory on a list of remote systems.

Usage: $(basename "$0") <options> [source] [target] [host/s]
Where:
[source]:	a specific file/directory to be copied to the remote host/s.
[target]:	a file/directory to be created/replaced by [source] on the remote host/s.
		note: [target] shall be relative to the remote home directory
[host/s]:	either a specific remote host to which [source] will be copied (e.g. \"user@host\"), OR
		a text file containing a list of hosts to which [source] will be copied.

The [source] and [target] arguments are mandatory.
If no [host/list] argument is provided, a list file of the name my_hosts.list will be used (if present).

Options:
-f	- Force script.  I.e. do not request confirmation of provided arguments.
-v	- Verbose output.
-h	- Print this help then exit.

Example: $(basename "${0}") ~/bin/stuff.sh bin/. my_hosts.list
"

FORCE=""			##Default setting, FORCE is false
DEST="/dev/null"	##Default output destination is /dev/null - option -v (verbose) changes destination to stdout.

##########Interpret options
while getopts 'fvh' OPTION; do				## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		f)	FORCE="TRUE" ;;			## -f forces the script to continue without requesting verification.
		v)	DEST="/dev/stdout" ;;		## -v activates verbose mode by sending output to /dev/stdout (instead of /ev/null).
		h)	echo -e "$USAGE"		## -l option just prints the usage then quits.
			exit 0				## Exit successfully.
			;;
		?)
			echo -e "Invalid option/s."
			echo -e "$USAGE"		## Invalid option, show usage.
			exit ${BAD_USAGE}		## Exit.
			;;
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

##########Check correct usage.
if [ $# -lt 2 ] || [ $# -gt 3 ]; then	##Check if less than two or more than three arguments were entered.
	echo -e "Bad argument/s."	##If so, show usage and exit.
	echo -e "${USAGE}"
	exit ${BAD_USAGE}
fi

##########Define the source and target arguments.
SOURCE=${1}	#First argument. File/directory to be copied.
TARGET=${2}	#Second argument. Destination relative to the remote home directory.

##########Define the hosts argument (user input or default).
HOSTS=${3-"$(dirname "$0")/my_hosts.list"}	#Third argument is the remote system or the file name of the list of remote systems.
						#If argument not provided, set default (by_hosts.list in same dir as script).
						#Syntax: parameter=${parameter-default}.

##########Define the temp files.
TEMP_ROLL_OUT_SUMMARY="$(dirname "$0")/TEMP_ROLL_OUT_SUMMARY"			#Define the temp summary file location.
if [ -e "${TEMP_ROLL_OUT_SUMMARY}" ]; then rm "${TEMP_ROLL_OUT_SUMMARY}"; fi	#If it exists, delete the temp file (in case script failed previously).

TEMP_REM_SYS_LIST="$(dirname "$0")/TEMP_REM_SYS_LIST"				#Define a working system list.
if [ -e "${TEMP_REM_SYS_LIST}" ]; then rm "${TEMP_REM_SYS_LIST}"; fi		#If it exists, delete the temporary file (in case script failed previously).

##########Validate the hosts argument and thus define the remote host/s.
##HOSTS is a single remote system.
if [ ! -f "${HOSTS}" ] || [ ! -r "${HOSTS}" ]; then				#If argument is not (!) a normal file (-f) or (||) it is not (!) readable (-r).
	if echo "${HOSTS}" | grep "@" > ${DEST} 2>&1; then
		HOST_NAME=$(echo ${HOSTS} | cut -d "@" -f 2)
	else	HOST_NAME="${HOSTS}"; fi
	if ping -c 1 -W 1 -q "${HOST_NAME}" > ${DEST} 2>&1; then		#If a ping to the host is successful...
		echo -e "\nRemote system is \"${HOSTS}\"." > ${DEST}		#Provided argument is probably a single host (either [host] or [user@host]).
		echo "${HOSTS}" > "${TEMP_REM_SYS_LIST}"			#Create the temp list file which will just contain the single entry.
		cat "${TEMP_REM_SYS_LIST}" > ${DEST}
	else
		echo -e "Specified host \"${HOSTS}\" appears invalid.  Quitting...\n"
		exit ${BAD_HOST}
	fi
##HOSTS specifies a list of remote hosts.
else
	echo -e "\nRemote system list is \"${HOSTS}\"." > ${DEST}		#Tell the user the list looks okay.
	while read -r LINE ; do							#Iterate for every line in the system list.
		STRIPPED_LINE="$(echo "${LINE}" | cut -d "#" -f 1)"		#Strip the content of the line after (and including) the first '#'.
		if [ "${STRIPPED_LINE}" ]; then					#If there is anything left in the string (i.e. if entire row is NOT a comment).
	  		echo "${STRIPPED_LINE}" >> "${TEMP_REM_SYS_LIST}"	#Then copy the stripped line to the temp file.
		fi
	done < "${HOSTS}"
fi

##########Print to screen what the entered command will attempt then request verification.  Will be skipped if option -f is used.
if [ ! "${FORCE}" ]; then
	echo -e "\nIt appears you intend to sync the following:"
	echo -e "Source file/directory: ${BOLD}${SOURCE}${RESET}"
	echo -e "Target file/directory: ${BOLD}~/${TARGET}${RESET}"
	echo -e "Target host/s:${BOLD}"
	cat ${TEMP_REM_SYS_LIST}
	echo -e "${RESET}"

	read -p "Continue? (y/n) " CHOICE
	case "${CHOICE}" in 
		y|Y)	;;	##Continue
		n|N)	echo -e "No.  Quittinq...\n"
			rm "${TEMP_REM_SYS_LIST}"	##Delete the temporary files.
			exit ${SUCCESS}
			;;
		*)	echo -e "Invalid, assume no.  Quitting...\n"
			rm "${TEMP_REM_SYS_LIST}"	##Delete the temporary files.
			exit ${SUCCESS}
			;;
	esac
fi

##########Loop through the remote system list.
while read -r REM_SYS <&2; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)

	echo -e "\n--------------------------------------------------------------------" > ${DEST}
	echo -e "${BLUE}Attempting to sync \"${RESET}${SOURCE}${BLUE}\" to \"${RESET}${REM_SYS}:~/${TARGET}${BLUE}\"${RESET}"

	(( NUM_BUFF=27-${#REM_SYS} ))			## Set the padding size based on the number of characters in the remote system hostname.
	COLUMN_SPACER=""
	for (( i=1; i<NUM_BUFF; i++ ))
	do
		COLUMN_SPACER="${COLUMN_SPACER}-"
	done

	##Attempt the file copy - if rsync fails, try scp.
	if ! rsync --progress --recursive --verbose "${SOURCE}" "${REM_SYS}":~/"${TARGET}" > ${DEST}; then		##If rsync fails
		echo -e "rsync unsuccessful.  Attempting to copy with scp..." > ${DEST}
		if ! scp -v -r "${SOURCE}" "${REM_SYS}":~/"${TARGET}" > ${DEST}; then					##If scp fails
			echo -E "${REM_SYS}${COLUMN_SPACER}${RED}Failure.${RESET}" >> "${TEMP_ROLL_OUT_SUMMARY}"	##Record the failure for the current host.
			echo -e "Both rsync and scp were ${RED}unsuccessful${RESET}.  Skipping to next host." > ${DEST}
			continue											##Skip to the next remote system.
		else 	echo -e "Copying with scp was ${GREEN}successful${RESET}." > ${DEST}; fi
	else 	echo -e "Copying with rsync was ${GREEN}successful${RESET}." > ${DEST}; fi
	echo -E "${REM_SYS}${COLUMN_SPACER}${GREEN}Success.${RESET}" >> "${TEMP_ROLL_OUT_SUMMARY}"	##At this point, either rsync or scp were successful.

done 2< "${TEMP_REM_SYS_LIST}"	##File read by the while loop which includes a list of files to be backed up.
echo -e "\n--------------------------------------------------------------------" > ${DEST}

##########Print out in a pretty format a table indicating the success or failure for each host in the list.
echo -e "${BOLD}\n╔═════════════Summary:═════════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}"
done < "${TEMP_ROLL_OUT_SUMMARY}"
echo -e "${BOLD}╚══════════════════════════════════╝${RESET}"
echo

rm "${TEMP_ROLL_OUT_SUMMARY}" "${TEMP_REM_SYS_LIST}"	##Delete the temporary files.

exit ${SUCCESS}
