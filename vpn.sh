#!/bin/bash

## I wrote this script to kill then reconnect the vpn (using openvpn).  Useful for when the connection starts acting up.
## Loop at the end will exit once once the script confirms the apparent ip has changed from the current.

## Colours.
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

## Exit codes.
SUCCESS=0
BAD_USAGE=1
BAD_CONFIG=2
NO_CURL=3
NO_IPINFO=4
OPENVPN_FAIL=5

## Define the default vpn config file to be used by openvpn.
## This is ignored if te user provides an argument defining an alternate config file.
DEFAULT_CONF="/home/jc/openvpn/Windscribe-Australia_UDP.ovpn"

## Define a temp file into which ipinfo.io data will be entered and then parsed.
TEMP_FILE=/tmp/vpn_tempfile

USAGE="
Usage: $(basename "${0}") <option> [openvpn config file]
Valid options:
	-c	Cancel running vpn. (Same as -k)
	-k	Kill running vpn. (Same as -c)
	-h	Help - Print this usage and exit.
"
##########Interpret options
while getopts 'ckh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		c|k)	echo -e "Cancelling vpn."	## -c (cancel) or -k (kill) will kill any running openvpn instance.
			sudo pkill openvpn
			exit ${SUCCESS}
			;;
		h)	echo -e "${USAGE}"		## -h option just prints the usage then quits.
			exit ${SUCCESS}			## Exit successfully.
			;;
		?)	echo -e "Invalid option/s."
			echo -e "$USAGE"		## Invalid option, show usage.
			exit ${BAD_USAGE}		## Exit.
			;;
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

##########Check correct usage
if [ $# -gt 1 ]; then								## Check if more than one argument was entered.
	echo -e "\n${RED}Error${RESET}: Too many arguments.  Quitting."		## If so, show usage and exit.
	echo -e "${USAGE}"
	exit ${BAD_USAGE}
fi

##########Define openvpn config file.
VPN_FILE=${1-"${DEFAULT_CONF}"}	## First argument is the openvpn config file.
				## If argument not provided, set default (defined at top of script).

##########Validate openvpn config file.
if [ ! -f "${VPN_FILE}" ]; then	## If file is not a regular file or is missing.
	echo -e "\n${RED}Error${RESET}: Invalid openvpn config file.  Quitting."
	echo -e "${USAGE}"
	exit ${BAD_CONFIG}
fi

##########Ensure curl is installed.
if ! command -v curl >> /dev/null; then
	echo -e "\n${RED}Error${RESET}: curl is not installed.  Quitting.\n"
	exit ${NO_CURL}
fi

##########Kill current openvpn instance before creating new.
echo -e "\nKilling any running instances of openvpn"
sudo pkill openvpn

##########Download current data from ipinfo.io into TEMP_FILE (this is the info without the vpn active).
if ! curl --silent --connect-timeout 5 --max-time 10 --output "$TEMP_FILE" ipinfo.io ; then ## Execute curl and check if it exited with a failure.
	echo -e "\n${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting...\n"
	exit ${NO_IPINFO}
fi

##########Parse specific details from the temp file.
CURRENT_IP=$(grep -m 1 "ip" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
CURRENT_CITY=$(grep "city" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)

##########Print out the current ip and city (without vpn).
echo -e "\nCurrent ip:   ${CURRENT_IP}"
echo -e  "Current city: ${CURRENT_CITY}"

##########Connect to the vpn.
echo -e "\nRunning openvpn using config file at \"$VPN_FILE\""
echo -e "\"$(basename "${0}") -c\" to cancel/kill vpn."
if ! sudo openvpn --config "${VPN_FILE}" --daemon ; then	## Execute openvpn. Exit script if it fails.
	rm "${TEMP_FILE}"
	echo -e "\n${RED}Error:${RESET} openvpn failed. Quitting"
	exit ${OPENVPN_FAIL}
fi

##########Loop until the vpn is active - determined by a change in the ip.
NEW_IP=${CURRENT_IP}
while [ "${NEW_IP}" == "${CURRENT_IP}" ]
do
	if ! curl --silent --connect-timeout 5 --max-time 10 --output "$TEMP_FILE" ipinfo.io ; then
		rm "$TEMP_FILE"
		echo -e "\n${RED}Error${RESET}: Failed to pull data from \"ipinfo.io\".  Quitting..."
		exit ${NO_IPINFO}
	fi
	NEW_IP=$(grep -m 1 "ip" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)
done
NEW_CITY=$(grep "city" "$TEMP_FILE" | cut -d ":" -f 2 | cut -d "\"" -f 2)

##########Print out the new apparent ip & city.
echo -e "\n${GREEN}Connected.${RESET}"
echo -e "New ip:   ${NEW_IP}"
echo -e "New city: ${NEW_CITY}\n"

##########Delete the temp file.
rm "$TEMP_FILE"

exit ${SUCCESS}
