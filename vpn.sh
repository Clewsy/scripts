#!/bin/bash

#I wrote this script to kill then reconnect the vpn (using openvpn).  Useful for when the connection starts acting up.
#Loop at the end will exit once once the script confirms the apparent ip has changed from the current.

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

#define the vpn config file to be used by openvpn.
VPN_FILE="/etc/openvpn/Windscribe-Australia.ovpn"

#define a temp file into which ipinfo.io data will be entered and then parsed
TEMP_FILE=$(dirname $BASH_SOURCE)/temp	#using $dirname of $BASH_SOURCE will create temp in the current working directory

#following if will quit the script if curl is not installed.
if [ ! $(which curl) ] ; then	#check if curl is not installed
	echo
	echo -e "${RED}Error${RESET}: curl is not installed.  Quitting."
	echo
	exit -1
fi

#kill current openvpn instance
echo
echo "Killing any running instances of openvpn"
sudo killall openvpn

#download current data from ipinfo.io into TEMP_FILE (this is the info without the vpn active)
curl --silent --connect-timeout 5 --max-time 10 --output $TEMP_FILE ipinfo.io
if [ $? != '0' ] ; then		#check if curl exited with a failure
	rm $TEMP_FILE
	echo
	echo -e "${RED}Error${RESET}: Failed to pull data from "ipinfo.io".  Quitting..."
	echo
	exit -1 
fi

#parse specific details from the temp file
current_ip=$(cat $TEMP_FILE | grep -m 1 "ip" | cut -d ":" -f 2 | cut -d "\"" -f 2)
current_city=$(cat $TEMP_FILE | grep "city" | cut -d ":" -f 2 | cut -d "\"" -f 2)

#print out the current ip and city (without vpn)
echo
echo "Current ip:   $current_ip"
echo "Current city: $current_city"

#connect to the vpn
echo
echo "Running openvpn using config file at \"$VPN_FILE\""
echo "(\"sudo killall openvpn\" to disable)"
sudo openvpn $VPN_FILE
#Following if will quit the script if openvpn exits with a failure
if [ $? != '0' ] ; then
	rm $TEMP_FILE
	echo
	echo -e "${RED}Error:${RESET} openvpn failed. Quitting"
	echo
	exit -1
fi

#loop until the vpn is active - determined by a change in the ip
new_ip=$current_ip
while [ "$new_ip" == "$current_ip" ]
do
	curl --silent --connect-timeout 5 --max-time 10 --output $TEMP_FILE ipinfo.io
	if [ $? != '0' ] ; then	#check if curl exited with a failure
		rm $TEMP_FILE
		echo
		echo -e "${RED}Error${RESET}: Failed to pull data from "ipinfo.io".  Quitting..."
		echo
		exit -1
	fi
	new_ip=$(cat $TEMP_FILE | grep -m 1  "ip" | cut -d ":" -f 2 | cut -d "\"" -f 2)
done
new_city=$(cat $TEMP_FILE | grep "city" | cut -d ":" -f 2 | cut -d "\"" -f 2)

#print out the new apparent ip & city
echo
echo -e "${GREEN}Connected.${RESET}"
echo "New ip:   $new_ip"
echo "New city: $new_city"
echo

rm $TEMP_FILE

exit 0
