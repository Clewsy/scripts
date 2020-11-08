#!/bin/bash

## This script will poll a url and check for a specified string.  The intention is to verify that a web-site is up and operating as expected.
## Commands can be specified to be run in the event that the web-site is operating fine, is down, or has recovered (was down but is operating again).
## By default, these events will trigger a change in colour of an LED indicator - a blink(1) usb LED - https://blink1.thingm.com/
## For this usage, the script must be run as sudo and the blink1-tool binary must be within the $PATH for root.
## The script can be run as a user cronjob, for example to run every 5 minutes:	*/5 * * * * sudo /usr/local/sbin/polly.sh
## Note, the script requires curl.

HOST_URL="https://clews.pro"	## Host url or ip address to test for connectivity

LOG_FILE="/var/log/polly.log"	## Log file location.

DEST="/dev/null"		## Default output destination.  Option -v sets to /dev/stdout for verbose output.
CURL_VERBOSITY="--silent"	## Default option for use with curl command.  Option -v removes this.

## Colour codes for the blink1-tool
BLINK_RED="--red"
BLINK_ORANGE="--rgb=255,165,0"
BLINK_GREEN="--green"
BLINK_BLUE="--blue"
BLINK_FLASH="--flash 1000"

##  Notifications handling function.
NOTIFICATION_f() {

	## Kill any current running blink routines.
	pkill blink1-tool

	## Determine desired colour and flashing status.
	case "$1" in
		START)		COLOUR=${BLINK_BLUE};	FLASH="" ;;
		FAILED)		COLOUR=${BLINK_RED};	FLASH=${BLINK_FLASH} ;;
		RECOVERED)	COLOUR=${BLINK_ORANGE};	FLASH="" ;;
		OK)		COLOUR=${BLINK_GREEN};	FLASH="" ;;
	esac

	## Run the blink command.
	blink1-tool ${COLOUR} ${FLASH} > ${DEST}
}

## Exit codes.
SUCCESS=0
BAD_OPTION=1
BAD_ARGUMENT=2
NO_ROOT=3
NO_CURL=4

## stdout output text colours.
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
RESET="\033[0m"

## Script usage.
USAGE="
Usage: $(basename "$0") [option]
Valid options:
-p	Standard poll: check site status, show & log the result. (requires root)
-s	Show the current status (i.e. result of last poll).
-l	Show the full log.
-r	Reset the recovered flag. (requires root)
-v 	Verbose output.
-h	Show help.
<none>	Same as -p, standard poll. (requires root)

Note, some options must be run with root/superuser privileges.
"

## Parse selected options.
while getopts 'pslrvh' OPTION; do						## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		p)	;;							## Run the standard poll commands - default option (same as no options).
		s)	echo -e "Fetching current status (last poll result):"	## Print the last line of the log file then exit.
			tail -n -1 ${LOG_FILE}
			exit $SUCCESS
			;;
		l)	echo -e "Printing log file (${LOG_FILE}):" 		## Simply dump the log file to stdout then exit.
			cat ${LOG_FILE}
			exit $SUCCESS
			;;
		r)	POLLY_RESET="true"					## Set flag to reset poll status.  Note, no exit.  After reset, the script will still run.
			;;
		v)	DEST="/dev/stdout"					## Change DEST from /dev/null to /dev/stdout for verbose output.
			CURL_VERBOSITY=""					## Remove the "--silent" option (used when calling curl command).
			;;
		h)	echo -e "${USAGE}"					## Print help (usage) and exit.
			exit $SUCCESS
			;;
		?)	echo -e "${USAGE}"					## Invalid option, show usage and exit.
			exit $BAD_OPTION
			;;
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

## No arguments are expected, so ensure not have been given.
echo -e "\nEnsuring no arguments were provided..." > ${DEST}
if (( $# > 0 )); then						## Check if an argument was entered.
	echo -e "${RED}Invalid argument.${RESET}\n ${USAGE}"	## If so, show usage and exit.
	exit $BAD_ARGUMENT
fi

## Verify that script was called with superuser permissions.
echo -e "\nChecking for superuser access..." > ${DEST}
if [[ $EUID -ne 0 ]]; then					## If userid is not that of root.
	echo -e "${RED}Permission denied.${RESET}\n ${USAGE}" 
	exit $NO_ROOT
fi

## Verify that curl is installed.
echo -e "\nChecking for curl..." > ${DEST}
if ! command -v curl > ${DEST}; then
	echo -e "${RED}Error${RESET}, curl is not installed.  Quitting..."
	exit $NO_CURL
fi


############ Main script functionality.

## Run a command to indicate the script is initiating.
echo -e "Running script-start notification function..." > ${DEST}
NOTIFICATION_f "START" &
sleep 1s

## Check for the RESET flag.  If set, reset the poll result then proceed with normal poll (use to clear "Warning" poll result).
if [[ -n "$POLLY_RESET" ]]; then
	echo -e "Clearing warning to reset site poll status."
	echo -e "$(date) - Site status reset." >> $LOG_FILE
fi

## Attempt to curl the url and obtain the response code for $HOST_URL.
TEST_RESULT=$(curl "${CURL_VERBOSITY}" --output /dev/stdout --write-out '%{http_code}' ${HOST_URL} | tail --lines 1)
echo -e "\nSite response code: ${TEST_RESULT}" > ${DEST}

## A site response code of 200 indicates everything is okay.
if [ "${TEST_RESULT}" != 200 ]; then										## Site is down.
	echo -e "\n${RED}FAILURE${RESET} - Site down!\n"
	echo -e "$(date) - FAILURE - Site not available. Curl returned ${TEST_RESULT}" >> $LOG_FILE
	echo -e "Running failure notification function..." > ${DEST}
	NOTIFICATION_f "FAILED" &
else
	if tail --lines 1 $LOG_FILE | grep -e "FAILURE" -e "WARNING" >> ${DEST}; then				## Site is up but was down.
		echo -e "\n${ORANGE}WARNING${RESET} - Site has recovered from downtime, but everything seems okay now.\n"
		echo -e "$(date) - WARNING - Site running but has recovered from downtime." >> $LOG_FILE
		echo -e "Running recovered notification function..." > ${DEST}
		NOTIFICATION_f "RECOVERED" &
	else													## Site is up.
		echo -e "\n${GREEN}SUCCESS${RESET} - Everything seems okay.\n"
		echo -e "$(date) - SUCCESS - Site is up, everything seems okay." >> $LOG_FILE
		echo -e "Running success notification command..." > ${DEST}
		NOTIFICATION_f "OK" &
	fi
fi
