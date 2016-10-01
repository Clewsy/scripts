#!/bin/bash

BOLD=`tput bold`
RESET=`tput sgr0`

echo
echo "Pulling data from "ipinfo.io"..."
curl -s -o temp ipinfo.io

ip=$(cat temp | grep "ip" | head -c-3 | tail -c+10)
hostname=$(cat temp | grep "hostname" | head -c-3 | tail -c+16)
city=$(cat temp | grep "city" | head -c-3 | tail -c+12)
region=$(cat temp | grep "region" | head -c-3 | tail -c+14)
country=$(cat temp | grep "country" | head -c-3 | tail -c+15)
loc=$(cat temp | grep "loc" | head -c-3 | tail -c+11)
org=$(cat temp | grep "org" | head -c-2 | tail -c+11)

echo
echo "${BOLD}IP:${RESET}------------ ${ip}"
echo "${BOLD}Hostname:${RESET}------ ${hostname}"
echo "${BOLD}City:${RESET}---------- ${city}"
echo "${BOLD}Region:${RESET}-------- ${region}"
echo "${BOLD}Country:${RESET}------- ${country}"
echo "${BOLD}Co-ordinates:${RESET}-- ${loc}"
echo "${BOLD}Organisation:${RESET}-- ${org}"
echo


rm temp



