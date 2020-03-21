#!/bin/bash

#I wrote this script to kill then reconnect the vpn (using openvpn).  Useful for when the connection starts acting up.
#Loop at the end will exit once once the script confirms the apparent ip has changed from the current.

#Colours.
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

#Exit codes.
SUCCESS=0
NO_CURL=1
NO_IPINFO=2
OPENVPN_FAIL=3

#Define the vpn config file to be used by openvpn.
#VPN_FILE="/etc/openvpn/Windscribe-Australia.ovpn"
VPN_FILE="/home/jc/openvpn/Windscribe-Australia_UDP.ovpn"

#Define a temp file into which ipinfo.io data will be entered and then parsed
TEMP_FILE=$(dirname "$0")/temp	#using $dirname of $0 will create temp in the current working directory

#Following if will quit the script if curl is not installed.
if [ ! "$(which curl)" ] ; then	#check if curl is not installed
	echo -e "\n${RED}Error${RESET}: curl is not installed.  Quitting.\n"
	exit ${NO_CURL}
fi

#Kill current openvpn instance
echo -e "\nKilling any running instances of openvpn"
sudo pkill openvpn

#Download current data from ipinfo.io into TEMP_FILE (this is the info without the vpn active)
if ! curl --silent --connect-timeout 5 --max-time 10 --output "$TEMP_FILE" ipinfo.io ; then #execute curl and check if it exited with a failure
	echo -e "\n${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting...\n"
	exit ${NO_IPINFO}
fi

#Parse specific details from the temp file
current_ip=$(grep -m 1 "ip" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
current_city=$(grep "city" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)

#Print out the current ip and city (without vpn)
echo -e "\nCurrent ip:	$current_ip"
echo -e "Current city:	$current_city"

#Connect to the vpn
echo -e "\nRunning openvpn using config file at \"$VPN_FILE\""
echo -e "(\"sudo pkill openvpn\" to disable)"
if ! sudo openvpn --config ${VPN_FILE} --daemon ; then	#Execute openvpn then exit script if it fails
	rm "${TEMP_FILE}"
	echo -e "\n${RED}Error:${RESET} openvpn failed. Quitting"
	exit ${OPENVPN_FAIL}
fi

#Loop until the vpn is active - determined by a change in the ip
new_ip=${current_ip}
while [ "${new_ip}" == "${current_ip}" ]
do
	if ! curl --silent --connect-timeout 5 --max-time 10 --output "$TEMP_FILE" ipinfo.io ; then	#Execute curl command but exit if it fails
		rm "$TEMP_FILE"
		echo -e "\n${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting..."
		exit ${NO_IPINFO}
	fi
	new_ip=$(grep -m 1 "ip" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
done
new_city=$(grep "city" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)

#Print out the new apparent ip & city
echo
echo -e "${GREEN}Connected.${RESET}"
echo "New ip:   $new_ip"
echo "New city: $new_city"
echo

#Delete the temp file.
rm "$TEMP_FILE"

exit ${SUCCESS}

