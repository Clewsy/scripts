#!/bin/bash

RED="\033[31m"
BOLD=$(tput bold)
RESET=$(tput sgr0)

TEMP_FILE="$(dirname "$0")/temp"	#define the temp file location so that the script will work even if run from a directory without write access

if [ ! "$(which curl)" ] ; then	#check if curl is not installed
	echo
	echo -e "${RED}Error${RESET}: curl is not installed.  Quitting."
	echo
	exit -1
fi

echo
echo "Pulling data from \"ipinfo.io\"..."
if ! curl --silent --connect-timeout 5 --max-time 10 --output "$TEMP_FILE" ipinfo.io; then	#run curl command bi check if it exited with a failure
	echo
	echo -e "${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting..."
	echo
	exit -1
fi
 
ip=$(grep -m 1 "ip" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
hostname=$(grep "hostname" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
city=$(grep "city" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
region=$(grep "region" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
country=$(grep "country" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
loc=$(grep "loc" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
org=$(grep "org" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)

echo
echo "${BOLD}IP:${RESET}------------ ${ip}"
echo "${BOLD}Hostname:${RESET}------ ${hostname}"
echo "${BOLD}City:${RESET}---------- ${city}"
echo "${BOLD}Region:${RESET}-------- ${region}"
echo "${BOLD}Country:${RESET}------- ${country}"
echo "${BOLD}Co-ordinates:${RESET}-- ${loc}"
echo "${BOLD}Organisation:${RESET}-- ${org}"
echo

rm "$TEMP_FILE"

exit 0
