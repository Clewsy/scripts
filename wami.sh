#!/bin/bash

RED="\033[00;31m"
BOLD="\033[01;37m"
RESET="\033[00;0m"

TEMP_FILE="$(dirname "$0")/temp"	#define the temp file location so that the script will work even if run from a directory without write access

if ! command -v curl >> /dev/null ; then	#check if curl is not installed
	echo
	echo -e "${RED}Error:${RESET}: curl is not installed.  Quitting."
	echo
	exit 1
fi

echo
echo "Pulling data from \"ipinfo.io\"..."
if ! curl --silent --connect-timeout 5 --max-time 10 --output "${TEMP_FILE}" ipinfo.io; then	#run curl command bi check if it exited with a failure
	echo
	echo -e "${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting..."
	echo
	exit 2
fi

IP=$(grep -m 1 "ip" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
POSTAL=$(grep -m 1 "postal" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
HOST_NAME=$(grep "hostname" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)	#Use the underscore since $HOSTNAME is already in use
CITY=$(grep "city" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
REGION=$(grep "region" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
COUNTRY=$(grep "country" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
LOC=$(grep "loc" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)
ORG=$(grep "org" "${TEMP_FILE}" | cut -d ":" -f 2 | cut -d "\"" -f 2)

echo
if [ -n "${IP}" ];		then echo -e "${BOLD}IP:${RESET}------------ ${IP}";		fi
if [ -n "${POSTAL}" ];		then echo -e "${BOLD}Post Code:${RESET}----- ${POSTAL}";	fi
if [ -n "${HOST_NAME}" ];	then echo -e "${BOLD}Hostname:${RESET}------ ${HOST_NAME}";	fi
if [ -n "${CITY}" ];		then echo -e "${BOLD}City:${RESET}---------- ${CITY}";		fi
if [ -n "${REGION}" ];		then echo -e "${BOLD}Region:${RESET}-------- ${REGION}";	fi
if [ -n "${COUNTRY}" ];		then echo -e "${BOLD}Country:${RESET}------- ${COUNTRY}";	fi
if [ -n "${LOC}" ];		then echo -e "${BOLD}Co-ordinates:${RESET}-- ${LOC}";		fi
if [ -n "${ORG}" ];		then echo -e "${BOLD}Organisation:${RESET}-- ${ORG}";		fi
echo

rm "${TEMP_FILE}"

exit 0
