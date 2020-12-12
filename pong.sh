#!/bin/bash
#: Title:	: pong
#: Author	: clewsy (clewsy.pro)
#: Description	: Quickly sequentially ping a list of hosts then provide a summary of the ping results.
#: Options	: -v - Verbose mode (show additional output).
#:		  -h - Help (print usage information).

## Colours and formatting
RED="\033[02;31m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
BOLD="\033[01;37m"
DIM="\\033[2m"
RESET="\033[0m"
TABLE_WIDTH=31
FILL_DASH_f () { for ((i=1; i<=$1; i++)); do printf "%s" "-"; done; } ## Print '-' a specified number of times.
FILL_DOUBLE_f () { for ((i=1; i<=$1; i++)); do printf "%s" "═"; done; } ## Print '═' a specified number of times.

## Exit codes
SUCCESS=0		## I guess it worked?
BAD_USAGE=1		## Bad option/s entered.
BAD_LIST_FILE=2		## Specified or default file list not readable
NO_PING=3		## ping is not installed/available.

DEST="/dev/null"	## Default destination for command output.  I.e. don't display on screen.  -v (verbose) option changes this.

## Usage
USAGE="
$(basename "$0") Sequentially ping a list of hosts to determine availibility on the network.

Usage: ${BOLD}$(basename "$0") <option> [host-list]${RESET}

Where [host-list] is a text list of remote systems to test for availability.

Entering no filename for a host-list defaults to ./my_hosts.list

Options:
-v : Verbose - print additional info to stdout.
-h : Print this usage and exit.

Example hosts format for the host-list:${BOLD}
hostname		${DIM}## As defined by the local network hosts list or a dns lookup.${RESET}${BOLD}
user@hostname		${DIM}## The user is discarded.${RESET}${BOLD}
ip-address		${DIM}## IPv4 or IPv6.${RESET}${BOLD}
user@ip-address		${DIM}## The user is discarded.${RESET}${BOLD}
"

############################## Input/syntax/error/dependency checking.

## Interpret options
while getopts 'vh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		v)	DEST="/dev/stdout" ;;		## -v activates verbose mode by directing output to /dev/stdout.
		h)	printf "%b" "${USAGE}\n"	## -h option just prints the usage then quits.
			exit ${SUCCESS} ;;		## Exit successfully.
		?)	printf "%b" "${USAGE}\n"	## Invalid option, show usage.
			exit ${BAD_USAGE} ;;		## Exit with error code.
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

## Check correct usage
if [ $# -gt 1 ]; then								## Check if more than one argument was entered.
	printf "%b" "${RED}Error.${RESET} Too many arguments.\n ${USAGE}\n"	## If so, show usage and exit.
	exit ${BAD_USAGE}
fi

## Validate the list of remote systems.
REM_SYS_LIST=${1-"$(dirname "$0")/my_hosts.list"}	## First argument is the file name of the list of remote systems.
							## If argument not provided, set default (my_hosts.list).
printf "%b" "\nRemote system list is \"${REM_SYS_LIST}\".\n" > ${DEST}
if [ ! -f "${REM_SYS_LIST}" ] || [ ! -r "${REM_SYS_LIST}" ]; then	## Ensure system list is normal (-f) and readable (-r).
	printf "%b" "\n${RED}Error:${RESET} Remote system list \"${BLUE}${REM_SYS_LIST}${RESET}\" not found, invalid file type or no read access.\n\n"
	exit ${BAD_LIST_FILE}
fi
printf "%b" "\n${GREEN}Success: ${RESET}Remote system list \"${BLUE}${REM_SYS_LIST}${RESET}\" validated.\n" > ${DEST}
printf "%b" "Raw host list:\n${BLUE}$(cat "${REM_SYS_LIST}")${RESET}\n" > ${DEST}

## Verify if ping is installed.
printf "%b" "\nChecking for ping:\n" > ${DEST}
if ! command -v ping > ${DEST}					#If rsync not installed
then	printf "%b" "${RED}Error:${RESET} ping not installed.\n\n"
	exit ${NO_PING}
else	printf "%b" "${GREEN}Success:${RESET} ping installed.\n" > ${DEST}
fi

############################## Main script functions.

## Define temporary  output summary file.
printf "%b" "\nCreating temp summary file: " > ${DEST}
TEMP_SUMMARY_FILE="/tmp/pong_summary"
> "${TEMP_SUMMARY_FILE}"
printf "%b" "${BLUE}${TEMP_SUMMARY_FILE}${RESET}\n" > ${DEST}

## Define temporary remote system list.
printf "%b" "\nCreating temp host list file: " > ${DEST}
TEMP_REM_SYS_LIST="/tmp/pong_temp_rem_sys_list"	
> "${TEMP_REM_SYS_LIST}"
printf "%b" "${BLUE}${TEMP_REM_SYS_LIST}${RESET}\n" > ${DEST}


## Strip any comments fromn the host list file.
printf "%b" "\nStripping comments and users from host list file.\n" > ${DEST}
while read -r LINE ; do								## Iterate for every line in the system list.
	STRIPPED_LINE="$(printf "%s" "${LINE}" | cut -d '#' -f 1)"		## Strip after (and including) the first '#'.
	STRIPPED_LINE="$(printf "%s" "${STRIPPED_LINE}" | cut -d "@" -f 2)"	## Strip before (and including) the first '@'.
	## If there is anything left hen copy the stripped line to the temp file.
	if [ "${STRIPPED_LINE}" ]; then printf "%b" "${STRIPPED_LINE}\n" >> "${TEMP_REM_SYS_LIST}"; fi
done < "${REM_SYS_LIST}"
printf "%b" "Host list with comments and users stripped:\n${BLUE}$(cat ${TEMP_REM_SYS_LIST})${RESET}\n" > ${DEST}

## Loop through the remote system list.
TALLY=0	## Initialise the tally of successful pings.
printf "%b" "\n────────Pinging────────" > ${DEST}
while read -r REM_SYS; do	## Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)

	printf "%b" "\nPinging ${REM_SYS}.." > ${DEST}	## Print current ping - keep the user updated on progress or stall point.
	printf "%b" "."					## Always print a period for every ping, verbose or standard mode.

	if ! ping -4 -c 1 -W 2 "${REM_SYS}" 2> ${DEST} 1> /dev/null; then	## Attempt to ping the current host machine.  Ping once (-c 1), wait for 1 second max (-w 1).
		printf "%b" "${GREEN}Ping${RESET} ${REM_SYS}${DIM}$(FILL_DASH_f $((TABLE_WIDTH-${#REM_SYS}-11)))${RESET}${RED}Miss${RESET}\n" >> "$TEMP_SUMMARY_FILE"		## Record failure.
	else
		printf "%b" "${GREEN}Ping${RESET} ${REM_SYS}${DIM}$(FILL_DASH_f $((TABLE_WIDTH-${#REM_SYS}-11)))${RESET}${GREEN}Pong${RESET}\n" >> "$TEMP_SUMMARY_FILE"		## Record failure.
		(( TALLY++ ))
	fi

done < "${TEMP_REM_SYS_LIST}"		## File read by the while loop which includes a list of files to be backed up.
printf "%b" "\n───────────────────────\n" > ${DEST}

## Print out in a pretty format a table indicating the success or failure of pinging each host in the list.
printf "%b" "\nPing attempts complete.  Printing summary:\n" > ${DEST}
printf "%b" "\n${BOLD}╔═Summary:$(FILL_DOUBLE_f $((TABLE_WIDTH-11)))╗${RESET}\n"
while read -r RESULT ; do
	printf "%b" "${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}\n"
done < "${TEMP_SUMMARY_FILE}"
printf "%b" "${BOLD}╠$(FILL_DOUBLE_f $((TABLE_WIDTH-2)))╣${RESET}\n"
printf "%b%03d%b%03d%b%$((TABLE_WIDTH-15))b" "${BOLD}║ " "${TALLY}" "${RESET} out of ${BOLD}" "$(wc -l ${TEMP_REM_SYS_LIST} | cut -d ' ' -f 1)" "${RESET} hosts online." "${BOLD}║${RESET}\n"
printf "%b" "${BOLD}╚$(FILL_DOUBLE_f $((TABLE_WIDTH-2)))╝${RESET}\n\n"

## Finish up.
printf "%b" "Deleting temp files.\n\n" > ${DEST}
rm "${TEMP_SUMMARY_FILE}" "${TEMP_REM_SYS_LIST}"

printf "%b" "Script completed ${GREEN}successfully${RESET}.\n\n" > ${DEST}
exit ${SUCCESS}
