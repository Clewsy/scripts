#!/bin/bash

HOST_URL="https://clews.pro/index.html"	#Host url or ip address to test for connectivity
HOST_STRING="work-in-progress"		#String that should result in a successful grep when cURL-ing the host.

LOG_FILE="/var/log/polly.log"

DEST="/dev/null"	#Default output destination.  Option -v sets to /dev/stdout for verbose output.

#Colour codes for the blink1-tool
BLINK_RED="--red"
BLINK_ORANGE="--rgb=255,165,0"
BLINK_GREEN="--green"
BLINK_BLUE="--blue"

#Commands for some kind of notifications.  E.g. send email.  Set to "" for nothing.
NOTIFICATION_FAILED="blink1-tool ${BLINK_RED}"
NOTIFICATION_RECOVERED="blink1-tool ${BLINK_ORANGE}"
NOTIFICATION_OK="blink1-tool ${BLINK_GREEN}"



## Exit codes.
SUCCESS=0
BAD_OPTION=1
BAD_ARGUMENT=2
NO_ROOT=3


USAGE="
Usage: $(basename $0) [option]
Valid options:
-r	Reset the recovered flag.
-l	Show the log.
-v 	Verbose output.
-h	Show help.

Note, must be run as root.
"

if [[ $EUID -ne 0 ]]; then
	echo -e "Permission denied.\n $USAGE" 
	exit $NO_ROOT
fi


while getopts 'rlvh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	OPTIONS="TRUE"				## Used to determine if a valid or invalid option was entered
	case "$OPTION" in
		r)	echo -e "Resetting site poll status."			## Note, no exit.  After reset, the script will still run.
			echo -e "$(date) - Site status reset." >> $LOG_FILE
			;;
		l)	echo -e "Printing log file (${LOG_FILE}):\n" 
			cat ${LOG_FILE}
			exit $SUCCESS
			;;
		v)	DEST="/dev/stdout" ;;
		h)	echo -e "$USAGE"		## Print help (usage).
			exit $SUCCESS			## Exit successfully.
			;;
		?)
			echo -e "$USAGE"		## Invalid option, show usage.
			exit $BAD_OPTION		## Exit.
			;;
	esac
done
shift $(($OPTIND -1))			## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.


if (( $# > 0 )); then			## Check if an argument was entered.
	echo -e "Invalid argument."	## If so, show usage and exit.
	echo -e "$USAGE"
	exit $BAD_ARGUMENT
fi

sudo blink1-tool ${BLINK_BLUE} > ${DEST}

if ! curl --silent --connect-timeout 5 --max-time 10 ${HOST_URL} | grep "${HOST_STRING}" >> ${DEST}; then
	echo -e "\nSite down!\n"
	echo -e "$(date) - FAILURE - Site not available." >> $LOG_FILE
	${NOTIFICATION_FAILED} > ${DEST}
else
	if tail --lines 1 $LOG_FILE | grep -e "FAILURE" -e "WARNING"; then
		echo -e "\nSite has recovered from downtime, but everything seems okay now.\n"
		echo -e "$(date) - WARNING - Site running but has recovered from downtime." >> $LOG_FILE
		${NOTIFICATION_RECOVERED} > ${DEST}
	else
		echo -e "\nEverything seems okay.\n"
		echo -e "$(date) - OK - Site is up, everything seems okay." >> $LOG_FILE
		${NOTIFICATION_OK} > ${DEST}
	fi
fi

