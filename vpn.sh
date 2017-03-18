#!/bin/bash

#I wrote this script to kill then reconnect the vpn (using openvpn).  Useful for when the connection starts acting up.
#Loop at the end will exit once once the script confirms the apparent city has changed from the current.
#This loop will be infinite if the vpn is in the same city as the machine.

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

#define the vpn config file to be used by openvpn.
VPN_FILE="/etc/openvpn/Windscribe-Australia.ovpn"

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

#determine the current city location (without vpn)
current_city=$(curl -s ipinfo.io | grep city | cut -d ":" -f 2 | cut -d "\"" -f 2)
new_city=$current_city

#print out the current city (without vpn)
echo
echo "Current city: $current_city"

#connect to the vpn
echo
echo "Running openvpn using config file at \"$VPN_FILE\""
echo "(\"sudo killall openvpn\" to disable)"
sudo openvpn $VPN_FILE
#Following if will quit the script if openvpn exits with a failure
if [ $? != '0' ] ; then
	echo
	echo -e "${RED}Error:${RESET} openvpn failed. Quitting"
	echo
	exit -1
fi

#loop until the vpn is active - determined by a change in the city
while [ "$new_city" == "$current_city" ]
do
	new_city=$(curl -s ipinfo.io | grep city | cut -d ":" -f 2 | cut -d "\"" -f 2)
done

#print out the new apparent city
echo
echo -e "${GREEN}Connected.${RESET}"
echo "New city: $new_city"
echo

exit 0

