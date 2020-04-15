#!/bin/bash

#This script will pull information regarding the default external ip address, then format this info and print to screen.
#Info is pulled from ipinfo.io.

#Text formatting codes.
RED="\033[00;31m"
BOLD="\033[01;37m"
RESET="\033[00;0m"

#Exit codes.
SUCCESS=0
NO_CURL=1
CURL_FAIL=2

TEMP_FILE="/tmp/wami_tempfile"			#Define the temp file location.

if ! command -v curl >> /dev/null ; then	#Check if curl is not installed.
	echo -e "\n${RED}Error:${RESET}: curl is not installed.  Quitting.\n"
	exit $NO_CURL
fi

echo -e "\nPulling data from \"ipinfo.io\"..."
if ! curl --silent --connect-timeout 5 --max-time 10 --output "${TEMP_FILE}" ipinfo.io; then	#Run curl command and check if it exited with a failure.
	echo -e "\n${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting...\n"
	if [[ -f "${TEMP_FILE}" ]]; then rm "${TEMP_FILE}"; fi					#Delete partial/incomplete ipinfo dump if it exists.
	exit $CURL_FAIL
fi

IP=$(grep -m 1 "ip" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
HOST_NAME=$(grep "hostname" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)		#Use the underscore since $HOSTNAME is already in use.
CITY=$(grep "city" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
REGION=$(grep "region" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
COUNTRY=$(grep "country" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
LOC=$(grep "loc" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
ORG=$(grep "org" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
POSTAL=$(grep -m 1 "postal" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
TIMEZONE=$(grep "timezone" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)

echo	#Start main output after a line break.
if [ -n "${IP}" ];		then echo -e "${BOLD}IP:${RESET}------------ ${IP}";		fi
if [ -n "${HOST_NAME}" ];	then echo -e "${BOLD}Hostname:${RESET}------ ${HOST_NAME}";	fi
if [ -n "${CITY}" ];		then echo -e "${BOLD}City:${RESET}---------- ${CITY}";		fi
if [ -n "${REGION}" ];		then echo -e "${BOLD}Region:${RESET}-------- ${REGION}";	fi
if [ -n "${COUNTRY}" ];		then echo -e "${BOLD}Country:${RESET}------- ${COUNTRY}";	fi
if [ -n "${LOC}" ];		then echo -e "${BOLD}Co-ordinates:${RESET}-- ${LOC}";		fi
if [ -n "${ORG}" ];		then echo -e "${BOLD}Organisation:${RESET}-- ${ORG}";		fi
if [ -n "${POSTAL}" ];		then echo -e "${BOLD}Post Code:${RESET}----- ${POSTAL}";	fi
if [ -n "${TIMEZONE}" ];	then echo -e "${BOLD}Timezone:${RESET}------ ${TIMEZONE}";	fi
echo	#Finish main output with a line break.

rm "${TEMP_FILE}"

exit $SUCCESS
