#!/bin/bash

## This script will poll a url and check for a specified string.  The intention is to verify that a web-site is up and operating as expected.
## Commands can be specified to be run in the event that the web-site is operating fine, is down, or has recovered (was down but is operating again).
## By default, these events will trigger a change in colour of an LED indicator - a blink(1) usb LED - https://blink1.thingm.com/
## For this usage, the script must be run as sudo and the blink1-tool binary must be within the $PATH for root.
## The script can be run as a user cronjob, for example to run every 5 minutes:	*/5 * * * * sudo /usr/local/sbin/polly.sh
## Note, the script requires curl.

HOST_URL="https://clews.pro/index.html"	## Host url or ip address to test for connectivity
HOST_STRING="work-in-progress"		## String that should result in a successful grep when cURL-ing the host.

LOG_FILE="/var/log/polly.log"		## Log file location.

DEST="/dev/null"			#Default output destination.  Option -v sets to /dev/stdout for verbose output.

## Colour codes for the blink1-tool
BLINK_RED="--red"
BLINK_ORANGE="--rgb=255,165,0"
BLINK_GREEN="--green"
BLINK_BLUE="--blue"

## Commands for some kind of notifications.  E.g. send email.  Set to "" for nothing.
NOTIFICATION_START="blink1-tool ${BLINK_BLUE}"
NOTIFICATION_FAILED="blink1-tool ${BLINK_RED}"
NOTIFICATION_RECOVERED="blink1-tool ${BLINK_ORANGE}"
NOTIFICATION_OK="blink1-tool ${BLINK_GREEN}"

## Exit codes.
SUCCESS=0
BAD_OPTION=1
BAD_ARGUMENT=2
NO_ROOT=3
NO_CURL=4

## Script usage.
USAGE="
Usage: $(basename $0) [option]
Valid options:
-r	Reset the recovered flag.
-l	Show the log.
-v 	Verbose output.
-h	Show help.

Note, must be run as root.
"

## Verify that script was called with superuser permissions.
echo -e "\nChecking for superuser access..." > ${DEST}
if [[ $EUID -ne 0 ]]; then
	echo -e "Permission denied.\n $USAGE" 
	exit $NO_ROOT
fi

## Verify that curl is installed.
echo -e "\nChecking for curl..." > ${DEST}
if ! command -v curl > ${DEST}; then
	echo -e "Error, curl is not installed.  Quitting..."
	exit $NO_CURL
fi

## Parse selected options.
while getopts 'rlvh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	OPTIONS="TRUE"				## Used to determine if a valid or invalid option was entered
	case "$OPTION" in
		r)	echo -e "Resetting site poll status."			## Note, no exit.  After reset, the script will still run.
			echo -e "$(date) - Site status reset." >> $LOG_FILE
			;;
		l)	echo -e "Printing log file (${LOG_FILE}):\n" 		## Simply dump the log file to stdout then exit.
			cat ${LOG_FILE}
			exit $SUCCESS
			;;
		v)	DEST="/dev/stdout" ;;					## Change DEST from /dev/null to /dev/stdout for verbose output.
		h)	echo -e "$USAGE"					## Print help (usage) and exit.
			exit $SUCCESS
			;;
		?)	echo -e "$USAGE"					## Invalid option, show usage and exit.
			exit $BAD_OPTION
			;;
	esac
done
shift $(($OPTIND -1))			## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

## No arguments are expected, so ensure not have been given.
if (( $# > 0 )); then			## Check if an argument was entered.
	echo -e "Invalid argument."	## If so, show usage and exit.
	echo -e "$USAGE"
	exit $BAD_ARGUMENT
fi

## Run a command to indicate the script is initiating.
${NOTIFICATION_START} > ${DEST}

## Attempt to curl the url and grep the string.
if ! curl --silent --connect-timeout 5 --max-time 10 ${HOST_URL} | grep "${HOST_STRING}" >> ${DEST}; then	## Site is down.
	echo -e "\nSite down!\n"
	echo -e "$(date) - FAILURE - Site not available." >> $LOG_FILE
	${NOTIFICATION_FAILED} > ${DEST}
else
	if tail --lines 1 $LOG_FILE | grep -e "FAILURE" -e "WARNING"; then					## Site is up but was down.
		echo -e "\nSite has recovered from downtime, but everything seems okay now.\n"
		echo -e "$(date) - WARNING - Site running but has recovered from downtime." >> $LOG_FILE
		${NOTIFICATION_RECOVERED} > ${DEST}
	else													## Site is up.
		echo -e "\nEverything seems okay.\n"
		echo -e "$(date) - OK - Site is up, everything seems okay." >> $LOG_FILE
		${NOTIFICATION_OK} > ${DEST}
	fi
fi

