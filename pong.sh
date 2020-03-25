#!/bin/bash

## Colours
RED="\033[02;31m"
GREEN="\033[02;32m"
BOLD="\033[01;37m"
DIM="\\033[2m"
RESET="\033[0m"

## Exit codes
SUCCESS=0		## I guess it worked?
BAD_USAGE=1		## Bad option/s entered.
BAD_LIST_FILE=2		## Specified or default file list not readable
NO_PING=3		## ping is not installed/available.

DEST="/dev/null"	## Default destination for command output.  I.e. don't display on screen.  -v (verbose) option changes this.

## Usage
USAGE="
$(basename "$0") runs a quick ping for a list of hosts to determine availibility on the network.

Usage: ${BOLD}$(basename "$0") <option> [host-list]${RESET}

Where [host-list] is a text list of remote systems to test for availability.

Entering no filename for a host-list defaults to ./my_hosts.list

Example hosts format for the host-list:
hostname		${DIM}## As defined by the locat network hosts list or a dns lookup.${RESET}
user@hostname		${DIM}## The user is discarded.${RESET}
ip-address		${DIM}## IPv4 or IPv6.${RESET}
user@ip-address		${DIM}## The user is discarded.${RESET}

Options:
	-v	- 	Verbose - print additional info to stdout.
	-h	-	Print this usage and exit.

"

############################## Input/syntax/error/dependency checking.

## Interpret options
while getopts 'vh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		v)	DEST="/dev/stdout" ;;	## -v activates verbose mode by sending output to /dev/stdout (instead of /dev/null).
		h)	echo -e "$USAGE"	## -h option just prints the usage then quits.
			exit ${SUCCESS} ;;	## Exit successfully.
		?)	echo -e "$USAGE"	## Invalid option, show usage.
			exit ${BAD_USAGE} ;;	## Exit.
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

## Check correct usage
if [ $# -gt 1 ]; then			## Check if more than one argument was entered.
	echo -e "Too many arguments."	## If so, show usage and exit.
	echo -e "${USAGE}"
	exit ${BAD_USAGE}
fi

## Validate the list of remote systems.
REM_SYS_LIST=${1-"$(dirname "$0")/my_hosts.list"}	## First argument is the file name of the list of remote systems.
							## If argument not provided, set default (my_hosts.list).
echo -e "\nRemote system list is \"${REM_SYS_LIST}\"." > ${DEST}
if [ ! -f "${REM_SYS_LIST}" ] || [ ! -r "${REM_SYS_LIST}" ]; then	## If ball.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "\n${RED}Failure:${RESET} Remote system list \"${REM_SYS_LIST}\" not found, invalid file type or no read access.\n"	## Output error message
	exit ${BAD_LIST_FILE}														## Exit
fi
echo -e "\n${GREEN}Confirmation: ${RESET}Remote system list \"${REM_SYS_LIST}\" validated." > ${DEST}	## Tell user the file list looks okay.

## Verify if ping is installed.
echo -e "\nChecking for ping:" > ${DEST}
if ! command -v ping > ${DEST}					#If rsync not installed
then	echo -e "\n${RED}Failure:${RESET} ping not installed.\n"
	exit ${NO_PING}
else	echo -e "\n${GREEN}Confirmation:${RESET} ping installed." > ${DEST}
fi

############################## Main script functions.

## Define temporary  output summary file.
echo -e "\nCreating temp summary file." > ${DEST}
TEMP_SUMMARY_FILE="/tmp/pong_summary"					## Define the temp file location so that the script will work even if run from a directory without write access
echo -e "${TEMP_SUMMARY_FILE}" > ${DEST}
if [ -e "${TEMP_SUMMARY_FILE}" ]; then rm "${TEMP_SUMMARY_FILE}"; fi	## If it exists, delete the temporary file (in case script failed previously before deleting it).

## Define temporary remote system list.
echo -e "\nCreating temp host list file." > ${DEST}
TEMP_REM_SYS_LIST="/tmp/pong_temp_rem_sys_list"				## Create the temporary rem_sys_list file.
echo -e "${TEMP_REM_SYS_LIST}" > ${DEST}
if [ -e "${TEMP_REM_SYS_LIST}" ]; then rm "${TEMP_REM_SYS_LIST}"; fi	## If it exists, delete it.

## Create a working system list from the original file list but with #comments stripped.
while read -r LINE ; do							## Iterate for every line in the system list.
	STRIPPED_LINE="$(echo "${LINE}" | cut -d "#" -f 1)"		## Strip the content of the line after (and including) the first '#'.
	if [ "${STRIPPED_LINE}" ] ; then				## If there is anything left in the string (i.e. if entire row is NOT a comment)
	  	echo "${STRIPPED_LINE}" >> "${TEMP_REM_SYS_LIST}"	## Then copy the stripped line to the temp file.
	fi
done < "${REM_SYS_LIST}"

## Loop through the remote system list.
echo -e "\n────────────────────Pinging────────────────────" > ${DEST}
while read -r REM_SYS; do	## Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)

	REM_HOST=$(echo "${REM_SYS}" | cut -d "@" -f 2)	## Strip the "user@" from the current entry in the hosts file.

	(( NUM_BUFF=23-${#REM_HOST} ))			## Set the padding size based on the number of characters in the hostname.
	COLUMN_SPACER=""
	for (( i=1; i<NUM_BUFF; i++ ))
	do
		COLUMN_SPACER="${COLUMN_SPACER}-"
	done

	echo -en "\nPinging ${REM_HOST}.." > ${DEST}	## Print current ping - keep the user updated on progress or stall point.
	echo -en "."					## Always print a period for every ping, verbose or standard mode.

	if ! ping -4 -c 1 -W 2 "${REM_HOST}" >> /dev/null; then	## Attempt to ping the current host machine.  Ping once (-c 1), wait for 1 second max (-w 1).
		echo "${GREEN}Ping${RESET} ${REM_HOST}${DIM}${COLUMN_SPACER}${RESET}${RED}Miss${RESET}" >> "$TEMP_SUMMARY_FILE"		## Record failure.
	else
		echo "${GREEN}Ping${RESET} ${REM_HOST}${DIM}${COLUMN_SPACER}${RESET}${GREEN}Pong${RESET}" >> "$TEMP_SUMMARY_FILE"	## Record success.
		(( TALLY++ ))
	fi

done < "${TEMP_REM_SYS_LIST}"		## File read by the while loop which includes a list of files to be backed up.

## Print out in a pretty format a table indicating the success or failure of ppinging each host in the list.
echo -e "\n\n${BOLD}╔═════Summary:══════════════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}"
done < "${TEMP_SUMMARY_FILE}"
echo -e "${BOLD}╠═══════════════════════════════╣${RESET}"
echo -e "${BOLD}║ ${TALLY}${RESET} out of ${BOLD}$(wc -l ${TEMP_REM_SYS_LIST} | cut -d " " -f 1)${RESET} hosts online.\t${BOLD}║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════╝${RESET}\n"

## Finish up.
rm "${TEMP_SUMMARY_FILE}"	## Delete the temporary summary file.
rm "${TEMP_REM_SYS_LIST}"	## Delete the temporary system list file.
exit ${SUCCESS}
