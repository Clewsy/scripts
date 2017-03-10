#!/bin/bash

BOLD=`tput bold`
RESET=`tput sgr0`

TEMP_FILE=$(dirname $BASH_SOURCE)/temp	#define the temp file location so that the script will work even if run from a directory without write access

echo
echo "Pulling data from "ipinfo.io"..."
curl -s -o $TEMP_FILE ipinfo.io

ip=$(cat $TEMP_FILE | grep -m 1 "ip" | cut -d ":" -f 2 | cut -d "\"" -f 2)
hostname=$(cat $TEMP_FILE | grep "hostname" | cut -d ":" -f 2 | cut -d "\"" -f 2)
city=$(cat $TEMP_FILE | grep "city" | cut -d ":" -f 2 | cut -d "\"" -f 2)
region=$(cat $TEMP_FILE | grep "region" | cut -d ":" -f 2 | cut -d "\"" -f 2)
country=$(cat $TEMP_FILE | grep "country" | cut -d ":" -f 2 | cut -d "\"" -f 2)
loc=$(cat $TEMP_FILE | grep "loc" | cut -d ":" -f 2 | cut -d "\"" -f 2)
org=$(cat $TEMP_FILE | grep "org" | cut -d ":" -f 2 | cut -d "\"" -f 2)

echo
echo "${BOLD}IP:${RESET}------------ ${ip}"
echo "${BOLD}Hostname:${RESET}------ ${hostname}"
echo "${BOLD}City:${RESET}---------- ${city}"
echo "${BOLD}Region:${RESET}-------- ${region}"
echo "${BOLD}Country:${RESET}------- ${country}"
echo "${BOLD}Co-ordinates:${RESET}-- ${loc}"
echo "${BOLD}Organisation:${RESET}-- ${org}"
echo


rm $TEMP_FILE



