#!/bin/bash

## This script will take an argument or either a single host, or a list of hosts.
## It will then run apt-get update, apt-get dist-upgrade, apt-get autoremove and then apt-get autoclean on the provided host/s.

## Colours.
RED="\033[02;31m"
GREEN="\033[02;32m"
BOLD="\033[01;37m"
BLUE="\033[01;34m"
RESET="\033[0m"

## Exit codes
SUCCESS=0	## Noice.
BAD_OPTION=1	## Invalid option.
BAD_USAGE=2	## Incorrect usage.

USAGE="
Usage: $(basename "$0") [hosts]
Where [hosts] can be:
	- [user@host]
	- [host]	(same user as current)
	- [hosts.list]	(file containing a list of [user@host] or [host]
	- ommitted	(script will look for host.list file of the name \"my_hosts.list\")
Valid options:
	-q	Quiet mode - only print the current host and the final summary.
	-v	Verbose mode - print additional info to stdout.  Overrides Quiet mode ("-q").
	-h	Print this usage and exit.
"

DEST="/dev/null"			## Default destination for command output.  I.e. don't display on screen.  -v (verbose) option changes this.
APT_GET_VERBOSITY="--quiet --quiet"	## Default verbosity setting for apt-get commands.  Removed by "-v" option.
QUIET=false

##########Interpret options
while getopts 'vqh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		q)	QUIET=true			## Set the quiet flag to suppress certain echo commands.
			;;
		v)	DEST="/dev/stdout"		## -v activates verbose mode by sending output to /dev/stdout (instead of /dev/null).
			APT_GET_VERBOSITY=""		## Verbose mode removes the "--quiet" option when apt-get commands are called.
			QUIET=false			## Override Quiet mode option.
			;;
		h)	echo -e "${USAGE}"		## -h option just prints the usage then quits.
			exit ${SUCCESS}			## Exit successfully.
			;;
		?)
			echo -e "Invalid option/s."
			echo -e "${USAGE}"		## Invalid option, show usage.
			exit ${BAD_OPTION}		## Exit wit error.
			;;
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

## Validate provided argument/s.
if [ $# -gt 1 ]; then		## If more than one argument is entered.
	echo -e "${USAGE}"	## Print the usage.
	exit ${BAD_USAGE}	## Exit.
fi

ARGUMENT=${1-"$(dirname "$0")/my_hosts.list"}	## First argument is the file name of the list of remote systems.
						## If argument not provided, set default (ball.list in same dir as script).
						## Syntax: parameter=${parameter-default}

TEMP_SUMMARY_FILE="/tmp/temp_apt_summary"				## Define temp summary file location.
if [ -e "${TEMP_SUMMARY_FILE}" ]; then rm "${TEMP_SUMMARY_FILE}"; fi	## If it exists, delete the temporary file (in case script failed previously).

TEMP_REM_SYS_LIST="/tmp/temp_apt_rem_sys_list"		## Define a working system list
if [ -e "${TEMP_REM_SYS_LIST}" ]; then rm "${TEMP_REM_SYS_LIST}"; fi	## If it exists, delete the temporary file (in case script failed previously).

## Determine the content of the specified option - i.e. a specific host or a lfile containing a list of hosts.
echo -e "\nValidating the target/s..." > ${DEST}
if [ ! -f "${ARGUMENT}" ] || [ ! -r "${ARGUMENT}" ]; then					## If argument is not (!) a normal file (-f) or (||) in is not (!) readable (-r).
	echo -e "Target is a specific host." > ${DEST}						## Then assume provided argument is a single host (either [host] or [user@host]).
	echo -e "Remote system is \"${BLUE}${ARGUMENT}${RESET}\"" > ${DEST}
	echo "${ARGUMENT}" > "${TEMP_REM_SYS_LIST}"						## Create the temp list file which will just contain the single entry.
else
	echo -e "Target is a list of hosts." > ${DEST}						## Provided argument is a readable file, assume list of hosts.
	echo -e "Remote system list \"${BLUE}${ARGUMENT}${RESET}\" validated.\n" > ${DEST}	## Tell the user the list looks okay.
	echo -e "Parsing hosts list...\n" > ${DEST}
	while read -r LINE ; do									## Iterate for every line in the system list.
		STRIPPED_LINE="$(echo "${LINE}" | cut -d "#" -f 1)"				## Strip the content of the line after (and including) the first '#'.
		if [ "${STRIPPED_LINE}" ]; then							## If there is anything left in the string (i.e. if entire row is NOT a comment).
	  		echo "${STRIPPED_LINE}" >> "${TEMP_REM_SYS_LIST}"			## Then copy the stripped line to the temp file.
		fi
	done < "${ARGUMENT}"
	echo -e "File \"${BLUE}${ARGUMENT}${RESET}\" contains the following list of hosts:" > ${DEST}	## Show the parsed list of hosts (i.e. provided list file with comments stripped).
	cat ${TEMP_REM_SYS_LIST} > ${DEST}
fi

## Loop through the remote system list.
echo -e "\n------------------------------------------------------" > ${DEST}
echo -e "\nBeginning apt-get commands on remote hosts..." > ${DEST}
while read -r REM_SYS <&2; do	## Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST).
				## <&2 needed as descriptor for nested while read loops (while read loop within called script).

	## For loop to set the tab spacing depending on the length of the hostname (makes the ouput summary pretty).
	let NUM_BUFF=32-${#REM_SYS}			## Total buffer = 32 minus number of chars in "user@host"
	COLUMN_SPACER=""
	for (( i=1; i<$NUM_BUFF; i++ )); do
		COLUMN_SPACER="${COLUMN_SPACER} "	## Add a space every iteration.
	done

	echo -E "${BOLD}║${REM_SYS}${COLUMN_SPACER}║${RESET}" >> "${TEMP_SUMMARY_FILE}"			## Record current system.
	echo -e "\n------------------------------------------------------" > ${DEST}
	echo -e "\nCurrent host: \t\t${BLUE}${REM_SYS}${RESET}"						## Print current system to stdout.

	###### Attempt connection.
	echo -e "Testing ssh connection to ${BLUE}${REM_SYS}${RESET}" > ${DEST}
	if [ ${QUIET} = false ]; then echo -e -n "${BOLD}ssh connection...\t${RESET}"; fi
	if ! ssh -o "BatchMode=yes" -o "ConnectTimeout=4" "${REM_SYS}" "exit" > /dev/null 2>&1; then	## Test ssh connection to current host machine.  If it fails...
		{
			echo -E "${BOLD}║${RED}System not found.${RESET}\t\t${BOLD}║${RESET}"
			echo -E "${BOLD}║${RESET}Skipped.\t\t\t${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record failure.
		if [ ${QUIET} = false ]; then echo -e "${RED}Error.${RESET} Skipping host."; fi
		continue			## Skip to the next system in the listi (if any).
	else												## Else ssh connection was successful.
		{
			echo -E "${BOLD}║${GREEN}System present.${RESET}\t\t${BOLD}║${RESET}"
			echo -E "${BOLD}║${RESET}Running apt-get commands:\t${BOLD}║${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record success.
		if [ ${QUIET} = false ]; then echo -e "${GREEN}Success.${RESET}"; fi
	fi

	###### Attempt update.
	if [ ${QUIET} = false ]; then echo -e -n "${BOLD}update... \t\t${RESET}"; fi
	if ! ssh -o "BatchMode=yes" "${REM_SYS}" "sudo apt-get ${APT_GET_VERBOSITY} --assume-yes update"; then
		{
			echo -E "${BOLD}║${RESET}apt-get update\t\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record failure.
		if [ ${QUIET} = false ]; then echo -e "${RED}Error.${RESET} Skipping..."; fi
		continue			## Skip to the next system in the list.
	else
		echo -E "${BOLD}║${RESET}apt-get update\t\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> "${TEMP_SUMMARY_FILE}"		## Record success.
		if [ ${QUIET} = false ]; then echo -e "${GREEN}Success.${RESET}"; fi
	fi

	###### Attempt dist-upgrade.
	if [ ${QUIET} = false ]; then echo -e -n "${BOLD}dist-upgrade... \t${RESET}"; fi
	if ! ssh -o "BatchMode=yes" "${REM_SYS}" "sudo apt-get ${APT_GET_VERBOSITY} --assume-yes --show-progress dist-upgrade"; then
		{
			echo -E "${BOLD}║${RESET}apt-get dist-upgrade\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record failure.
		if [ ${QUIET} = false ]; then echo -e "${RED}Error.${RESET} Skipping..."; fi
		continue			## Skip to the next system in the list.
	else
		echo -E "${BOLD}║${RESET}apt-get dist-upgrade\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> "${TEMP_SUMMARY_FILE}"	## Record success.
		if [ ${QUIET} = false ]; then echo -e "${GREEN}Success.${RESET}"; fi
	fi

	###### Attempt autoremove.
	if [ ${QUIET} = false ]; then echo -e -n "${BOLD}autoremove... \t\t${RESET}"; fi
	if ! ssh -o "BatchMode=yes" "${REM_SYS}" "sudo apt-get ${APT_GET_VERBOSITY} --assume-yes --show-progress autoremove"; then
		{
			echo -E "${BOLD}║${RESET}apt-get autoremove\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record failure.
		if [ ${QUIET} = false ]; then echo -e "${RED}Error.${RESET} Skipping..."; fi
		continue			## Skip to the next system in the list.
	else
		echo -E "${BOLD}║${RESET}apt-get autoremove\t${GREEN}Success.${RESET}${BOLD}║${RESET}" >> "${TEMP_SUMMARY_FILE}"	## Record success.
		if [ ${QUIET} = false ]; then echo -e "${GREEN}Success.${RESET}"; fi
	fi

	###### Attempt autoclean.
	if [ ${QUIET} = false ]; then echo -e -n "${BOLD}autoclean... \t\t${RESET}"; fi
	if ! ssh -o "BatchMode=yes" "${REM_SYS}" "sudo apt-get ${APT_GET_VERBOSITY} --assume-yes autoclean"; then
		{
			echo -E "${BOLD}║${RESET}apt-get autoclean\t${RED}Failure.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record failure.
		if [ ${QUIET} = false ]; then echo -e "${RED}Error.${RESET} Skipping..."; fi
		continue			## Skip to the next system in the list.
	else
		{
			echo -E "${BOLD}║${RESET}apt-get autoclean\t${GREEN}Success.${RESET}${BOLD}║${RESET}"
			echo -E "${BOLD}╠═══════════════════════════════╣${RESET}"
		} >> "${TEMP_SUMMARY_FILE}"	## Record success.
		if [ ${QUIET} = false ]; then echo -e "${GREEN}Success.${RESET}"; fi
	fi

done 2< "${TEMP_REM_SYS_LIST}"		## File read by the while loop which includes a list of files to be backed up.

## Print out in a pretty format a table indicating the success or failure for each host in the list.
echo -e "\n${BOLD}╔═Summary:══════════════════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${RESULT}"
done < "${TEMP_SUMMARY_FILE}"
echo -e "${BOLD}║${RESET}Script complete.\t\t${BOLD}║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════╝${RESET}"
echo

rm "${TEMP_SUMMARY_FILE}"	## Delete the temporary summary file.
rm "${TEMP_REM_SYS_LIST}"	## Delete the temporary system list file.

exit ${SUCCESS}
