#!/bin/bash

## This script will taka a remote host or list of hosts, then run the backup script "bu.sh" for each.
## That said, the "COMMAND" variable can be set to anything you want to run on multiple systems.

COMMAND="~/bin/bu.sh"	## The command to run on the remote host/s.  Note using "~" avoids expanding on the client side.

##########Colours.
RED="\033[02;31m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
BOLD="\033[01;37m"
RESET="\033[0m"

##########Exit codes
SUCCESS=0	## Toight.
BAD_USAGE=1	## Incorrect usage.

#########Usage
USAGE="
Usage: $(basename "$0")[option] [host/list]
Where [host/list] is either:
	host	-	a specific remote system on which command \"${COMMAND}\" will be run.
	list	-	a text list of remote systems on which command \"${COMMAND}\" will be run.

If no argument is provided, a list file of the name my_hosts.list will be used (if present).

Options:	-v	Verbose output.
		-h	Show this help.
"

VERBOSITY=""		## Define the default verbosity (i.e. none).  Can be changed with option -v.
DEST="/dev/null"	## Default destination for output.  Change to /dev/stdout with option -v.

##########Interpret options
while getopts 'fvh' OPTION; do				## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		v)	VERBOSITY="-v"			## -v activates verbose mode by iadding the -v flag to the bu.sh command.
			DEST="/dev/stdout" ;;
		h)	echo -e "${USAGE}"		## -h option just prints the usage then quits.
			exit ${SUCCESS} ;;		## Exit successfully.
		?)	echo -e "Invalid option/s."
			echo -e "${USAGE}"		## Invalid option, show usage.
			exit ${BAD_USAGE} ;;		## Exit.
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.


##########Check correct usage.
if [ $# -gt 1 ]; then			## Check if more than one argument was entered.
	echo -e "Too many arguments."	## If so, show usage and exit.
	echo -e "${USAGE}"
	exit ${BAD_USAGE}
fi

##########Define the argument (user input or default).
ARGUMENT=${1-"$(dirname "$0")/my_hosts.list"}	## First argument is the file name of the list of remote systems.
						## If argument not provided, set default (by_hosts.list in same dir as script).
						## Syntax: parameter=${parameter-default}.

##########Define the temp files.
TEMP_BALL_SUMMARY="/tmp/temp_ball_summary"				## Define the temp summary file location.
if [ -e "${TEMP_BALL_SUMMARY}" ]; then rm "${TEMP_BALL_SUMMARY}"; fi	## If it exists, delete the temp file (in case script failed previously).

TEMP_REM_SYS_LIST="/tmp/temp_rem_sys_list"				## Define a working system list.
if [ -e "${TEMP_REM_SYS_LIST}" ]; then rm "${TEMP_REM_SYS_LIST}"; fi	## If it exists, delete the temporary file (in case script failed previously).


##########Validate the argument and thus define the remote host/s.
## Arg specifies a remote host.
if [ ! -f "${ARGUMENT}" ] || [ ! -r "${ARGUMENT}" ]; then	## If argument is not (!) a normal file (-f) or (||) in is not (!) readable (-r).
	echo -e "\n${BLUE}Remote system is \"${RESET}${ARGUMENT}${BLUE}\".${RESET}"		## Then assume provided argument is a single host (either [host] or [user@host]).
	echo "${ARGUMENT}" > "${TEMP_REM_SYS_LIST}"		## Create the temp list file which will just contain the single entry.
## Arg specifies a list of remote hosts.
else
	echo -e "\n${BLUE}Remote system list is \"${RESET}${ARGUMENT}${BLUE}\".${RESET}"			## Tell the user the list looks okay.
	while read -r LINE ; do							## Iterate for every line in the system list.
		STRIPPED_LINE="$(echo "${LINE}" | cut -d "#" -f 1)"		## Strip the content of the line after (and including) the first '#'.
		if [ "${STRIPPED_LINE}" ]; then					## If there is anything left in the string (i.e. if entire row is NOT a comment).
	  		echo "${STRIPPED_LINE}" >> "${TEMP_REM_SYS_LIST}"	## Then copy the stripped line to the temp file.
		fi
	done < "${ARGUMENT}"
	echo -e "\n${BLUE}Target systems:${RESET}" >> ${DEST}
	cat "${TEMP_REM_SYS_LIST}" >> ${DEST}	## Show the intended target systems (when verbose option is used).
fi

########## Loop through the remote system list.
echo -e "\n----------------------------------------------------------------------------------"
while read -r REM_SYS <&2; do	## Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
				## <&2 needed as descriptor for nested while read loops (while read loop within called script)

	echo -e "${BLUE}Attempting to run \"${RESET}${COMMAND}${BLUE}\" on \"${RESET}${REM_SYS}${BLUE}\"${RESET}"

	## For loop to set the tab spacing depending on the length of the hostname (makes the ouput summary pretty).
	let NUM_BUFF=24-${#REM_SYS}			## Total buffer = 24 minus number of chars in "user@host"
	COLUMN_SPACER=""
	for (( i=1; i<$NUM_BUFF; i++ )); do
		COLUMN_SPACER="${COLUMN_SPACER} "	## Add a space every iteration.
	done

	if ! ssh -t "${REM_SYS}" "${COMMAND} ${VERBOSITY}"; then						## Attempt to connect via ssh and run the backup script "bu.sh"
		echo -E "${REM_SYS}${COLUMN_SPACER} ${RED}Failure.${RESET}" >> "${TEMP_BALL_SUMMARY}"		## Record if the above fails for the current host.
		echo -e "${RED}Failure.${RESET}"								## Also show failure on stdio.
		echo -e "----------------------------------------------------------------------------------"
		continue											## Then try the next host in the list.
	else
		echo -E "${REM_SYS}${COLUMN_SPACER} ${GREEN}Success.${RESET}" >> "${TEMP_BALL_SUMMARY}"		## If the above succeeds, record the success.
		echo -e "----------------------------------------------------------------------------------"	## Note a "success" means the ssh session was created and exited.
														##  gracefully.  Failures with the called script are not checcked.
	fi

done 2< "${TEMP_REM_SYS_LIST}"		## File read by the while loop which includes a list of files to be backed up.

########### Print out in a pretty format a table indicating the success or failure for each host in the list.
echo -e "${BOLD}\n╔════════════Summary:════════════╗${RESET}"
while read -r RESULT ; do
	echo -e "${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}"
done < "${TEMP_BALL_SUMMARY}"
echo -e "${BOLD}╚════════════════════════════════╝${RESET}\n"

########## All done.
rm "${TEMP_BALL_SUMMARY}" "${TEMP_REM_SYS_LIST}"	## Delete the temporary files.
exit ${SUCCESS}
