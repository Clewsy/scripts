#!/bin/bash

## Set main heading colour from options above.
#COL="\\033[00;30m"		#BLACK
#COL="\\033[00;31m"		#RED
#COL="\\033[00;32m"		#GREEN
#COL="\\033[00;33m"		#YELLOW
#COL="\\033[00;34m"		#BLUE
#COL="\\033[00;35m"		#MAGENTA
COL="\\033[00;36m"		#CYAN
#COL="\\033[00;37m"		#GRAY
#COL="\\033[01;37m"		#WHITE

BOLD="\\033[1m"
DIM="\\033[2m"
RESET="\\033[0m"

USAGE="
Usage: $(basename $0) [option]
Valid options:
-p	Product info
-c 	CPU info
-m	Memory info
-a	Audio hardware info
-v	Video hardware info
-d	Disks and partitions info
-o	Operating system and kernel info
-n	Network info
-h	Print this help
"

while getopts 'pcmavdonh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	OPTIONS="TRUE"					## Used to determine if a valid or invalid option was entered
	case "$OPTION" in
		p)	GET_P_PRODUCT_INFO="TRUE" ;;	## Set P flag - product info (inc. motherboard, chassis, bios)
		c)	GET_C_CPU_INFO="TRUE" ;;	## Set C flag - cpu
		m)	GET_M_MEMORY_INFO="TRUE" ;;	## Set M flag - memory
		a)	GET_A_AUDIO_INFO="TRUE" ;;	## Set A flag - audio hardware
		v)	GET_V_VIDEO_INFO="TRUE" ;;	## Set V flag - video hardware
		d)	GET_D_DISKS_INFO="TRUE" ;;	## Set D flag - disks and partitions (inc. raid)
		o)	GET_O_OS_INFO="TRUE" ;;		## Set O flag - operating system (inc. kernel)
		n)	GET_N_NETWORK_INFO="TRUE" ;;	## Set N flag - network
		h)	echo -e "$USAGE"		## Print help (usage).
			exit 0				## Exit successfully.
			;;
		?)
			echo -e "$USAGE"		## Invalid option, show usage.
			exit 1				## Exit.
			;;
	esac
done
shift $(($OPTIND -1))			## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

if [ -z "$OPTIONS" ]; then		## Check if no options were entered.
	GET_ALL_INFO="TRUE"		## If so, set the ALL flag.
fi

if (( $# > 0 )); then			## Check if an argument was entered.
	echo -e "Invalid argument."	## If so, show usage and exit.
	echo -e "$USAGE"
	exit 2
fi

echo
echo -e "${COL}╔════════════════════╗${RESET}"
echo -e "${COL}║${RESET} ${BOLD}System Information ${RESET}${COL}║${RESET}"
echo -e "${COL}╚════════════════════╝${RESET}"

###############################################################################################################################################################
## Print available product, chassis, motherboard, bios info
if [[ -n "$GET_P_PRODUCT_INFO" || -n "$GET_ALL_INFO" ]]; then
	###############################
	## Print available product info
	if [ -s /sys/devices/virtual/dmi/id/product_name ]; then
		PRODUCT_NAME=$(cat /sys/devices/virtual/dmi/id/product_name)
		PRODUCT_VERSION=$(cat /sys/devices/virtual/dmi/id/product_version)
		SYS_VENDOR=$(cat /sys/devices/virtual/dmi/id/sys_vendor)
		if [ -n "${PRODUCT_NAME}" ]; then
			if [ -n "${PRODUCT_VERSION}" ]; then
				if [ -n "${SYS_VENDOR}" ]; then
					echo -e "${COL}${BOLD}Product:${RESET} ${PRODUCT_NAME}, version ${PRODUCT_VERSION} (${SYS_VENDOR})"
				else
					echo -e "${COL}${BOLD}Product:${RESET} ${PRODUCT_NAME}, version ${PRODUCT_VERSION}"
				fi
			elif [ -n "${SYS_VENDOR}" ]; then
				echo -e "${COL}${BOLD}Product:${RESET} ${PRODUCT_NAME} (${SYS_VENDOR})"
			else
				echo -e "${COL}${BOLD}Product:${RESET} ${PRODUCT_NAME}"
			fi
		fi
	else
		echo -e "Product information not found"
	fi

	###############################
	## Print available chassis info
	if [ -s /sys/devices/virtual/dmi/id/chassis_type ]; then
		CHASSIS_TYPE=$(cat /sys/devices/virtual/dmi/id/chassis_type)
		CHASSIS_VERSION=$(cat /sys/devices/virtual/dmi/id/chassis_version)
		CHASSIS_VENDOR=$(cat /sys/devices/virtual/dmi/id/chassis_vendor)
		if [ -n "${CHASSIS_TYPE}" ]; then
	        	if [ -n "${CHASSIS_VERSION}" ]; then
				if [ -n "${CHASSIS_VENDOR}" ]; then
					echo -e "${COL}${BOLD}Chassis:${RESET} ${CHASSIS_TYPE}, version ${CHASSIS_VERSION} (${CHASSIS_VENDOR})"	## Chassis type, version, vendor
				else
					echo -e "${COL}${BOLD}Chassis:${RESET} ${CHASSIS_TYPE}, version ${CHASSIS_VERSION}"			## Chassis type, version
				fi
			elif [ -n "${CHASSIS_VENDOR}" ]; then
				echo -e "${COL}${BOLD}Chassis:${RESET} ${CHASSIS_TYPE} (${CHASSIS_VENDOR})"					## Chassis type, vendor
			fi
		else
			echo -e "${COL}${BOLD}Chassis:${RESET} ${CHASSIS_TYPE}"									## Chassis type
		fi
	else
		echo -e "Chassis information not found"
	fi

	###############################
	## Print available motherboard info
	if [ -s /sys/devices/virtual/dmi/id/board_name ]; then
		BOARD_NAME=$(cat /sys/devices/virtual/dmi/id/board_name)
		BOARD_VERSION=$(cat /sys/devices/virtual/dmi/id/board_version)
		BOARD_VENDOR=$(cat /sys/devices/virtual/dmi/id/board_vendor)
		if [ -n "${BOARD_NAME}" ]; then
			if [ -n "${BOARD_VERSION}" ]; then
				if [ -n "${BOARD_VENDOR}" ]; then
					echo -e "${COL}${BOLD}Motherboard:${RESET} ${BOARD_NAME}, version ${BOARD_VERSION} (${BOARD_VENDOR})"	## Motherboard model, version, vendor
				else
					echo -e "${COL}${BOLD}Motherboard:${RESET} ${BOARD_NAME}, version ${BOARD_VERSION}"			## Motherboard model, version
				fi
			elif [ -n "${BOARD_VENDOR}" ]; then
				echo -e "${COL}${BOLD}Motherboard:${RESET} ${BOARD_NAME} (${BOARD_VENDOR})"					## Motherboard name, vendor
			else
				echo -e "${COL}${BOLD}Motherboard:${RESET} ${BOARD_NAME}"							## Motherboard model
			fi
		fi
	else
		echo -e "Motherboard information not found"
	fi

	###############################
	## Print available bios info
	if [ -s /sys/devices/virtual/dmi/id/bios_date ]; then
		BIOS_DATE=$(cat /sys/devices/virtual/dmi/id/bios_date)
		BIOS_VERSION=$(cat /sys/devices/virtual/dmi/id/bios_version)
		BIOS_VENDOR=$(cat /sys/devices/virtual/dmi/id/bios_vendor)
		if [ -n "${BIOS_DATE}" ]; then
			if [ -n "${BIOS_VERSION}" ]; then
				if [ -n "${BIOS_VENDOR}" ]; then
					echo -e "${COL}${BOLD}Bios:${RESET} ${BIOS_DATE}, version ${BIOS_VERSION} (${BIOS_VENDOR})"	## Bios date, version, vendor
				else
					echo -e "${COL}${BOLD}Bios:${RESET} ${BIOS_DATE}, version ${BIOS_VERSION}"			## Bios date, version
				fi
			elif [ -n "${BIOS_VENDOR}" ]; then
				echo -e "${COL}${BOLD}Bios:${RESET} ${BIOS_DATE} (${BIOS_VENDOR})"					## Bios date, vendor
			else
				echo -e "${COL}${BOLD}Bios:${RESET} ${BIOS_DATE}"							## Bios date
			fi
		fi
	else
		echo -e "Bios information not found"
	fi
fi

###############################################################################################################################################################
## Print available CPU info
if [[ -n "$GET_C_CPU_INFO" || -n "$GET_ALL_INFO" ]]; then
	if ! command -v lscpu >> /dev/null ; then	#If lscpu not installed (send to /dev/null to suppress stdout)
		echo -e "Cannot determine cpu infomtion (lscpu not installed)"
	else
		CPU_MODEL=$(lscpu | grep "Model name" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_VENDOR=$(lscpu | grep "Vendor ID" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_ARCH=$(lscpu | grep "Architecture" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_MODE=$(lscpu | grep "CPU op-mode" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_CORES=$(lscpu | grep -m 1 "CPU(s)" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_SPEED=$(lscpu | grep "CPU MHz" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_MAX_SPEED=$(lscpu | grep "CPU max" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		CPU_MIN_SPEED=$(lscpu | grep "CPU min" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
		echo -e "${COL}${BOLD}CPU:${RESET}"
		if [ -n "${CPU_MODEL}" ];	then echo -e "${COL}--Model:${RESET} ${CPU_MODEL}"; fi			## CPUModel and vendor
		if [ -n "${CPU_VENDOR}" ];	then echo -e "${COL}--Vendor:${RESET} ${CPU_VENDOR}"; fi		## CPUModel and vendor
		if [ -n "${CPU_ARCH}" ];	then echo -e "${COL}--Architecture:${RESET} ${CPU_ARCH}"; fi		## Architecture
		if [ -n "${CPU_MODE}" ];	then echo -e "${COL}--Mode(s):${RESET} ${CPU_MODE}"; fi			## CPU op-mode(s)
		if [ -n "${CPU_CORES}" ];	then echo -e "${COL}--Cores:${RESET} ${CPU_CORES}"; fi			## CPU(s)
		if [ -n "${CPU_SPEED}" ];	then echo -e "${COL}--Speed:${RESET} ${CPU_SPEED}MHz"; fi		## CPU MHz
		if [ -n "${CPU_MAX_SPEED}" ];	then echo -e "${COL}--Max Speed:${RESET} ${CPU_MAX_SPEED}MHz"; fi	## Max CPU MHz
		if [ -n "${CPU_MIN_SPEED}" ];	then echo -e "${COL}--Min Speed:${RESET} ${CPU_MIN_SPEED}MHz"; fi	## Min CPU MHz
	fi
fi

###############################################################################################################################################################
## Print memory info
if [[ -n "$GET_M_MEMORY_INFO" || -n "$GET_ALL_INFO" ]]; then
	echo -e "${COL}${BOLD}Memory:${RESET}"
	echo -e "${COL}--RAM:${RESET}"
	echo -e "${COL}${DIM}----Total:${RESET} $(free -h | grep "Mem:" | awk '{print $2}')"	## Print total physical RAM
	echo -e "${COL}${DIM}----Used:${RESET}  $(free -h | grep "Mem:" | awk '{print $3}')"	## Print used physical RAM
	echo -e "${COL}${DIM}----Free:${RESET}  $(free -h | grep "Mem:" | awk '{print $4}')"	## Print free physical RAM
	echo -e "${COL}--SWAP:${RESET}"
	echo -e "${COL}${DIM}----Total:${RESET} $(free -h | grep "Swap" | awk '{print $2}')"	## Print total allocated swap file size
	echo -e "${COL}${DIM}----Used:${RESET}  $(free -h | grep "Swap" | awk '{print $3}')"	## Print used swap file size
	echo -e "${COL}${DIM}----Free:${RESET}  $(free -h | grep "Swap" | awk '{print $4}')"	## Print free swap file size
fi

###############################################################################################################################################################
## Print audio and video info (note only first result of each if multiple video or audio devices exist)
if [[ -n "$GET_A_AUDIO_INFO" || -n "$GET_V_VIDEO_INFO" || -n "$GET_ALL_INFO" ]]; then
	if ! command -v lspci >> /dev/null ; then		#If lspci not installed (send to /dev/null to suppress stdout)
		echo -e "Cannot determine audio or video information (lspci not installed)"
	else
		if [[ -n "$GET_A_AUDIO_INFO" || -n "$GET_ALL_INFO" ]]; then
			AUDIO_INFO=$(lspci -k | grep -m 1 Audio | cut -c23-)
			if [ -n "${AUDIO_INFO}" ]; then
				echo -e "${COL}${BOLD}Audio:${RESET} ${AUDIO_INFO}"	## Audio info
			else
				echo -e "Audio information not found"
			fi
		fi
		if [[ -n "$GET_V_VIDEO_INFO" || -n "$GET_ALL_INFO" ]]; then
			VIDEO_INFO=$(lspci -k | grep -m 1 VGA | cut -c36-)
			if [ -n "${VIDEO_INFO}" ]; then
				echo -e "${COL}${BOLD}Video:${RESET} ${VIDEO_INFO}"	## Video info
			else
				echo -e "Video information not found"
			fi
		fi
	fi
fi

###############################################################################################################################################################
## Print disk and partition info
if [[ -n "$GET_D_DISKS_INFO" || -n "$GET_ALL_INFO" ]]; then
	if ! command -v lsblk >> /dev/null ; then	#If lsblk not installed (send to /dev/null to suppress stdout)
		echo -e "Cannot determine disk/partition information (lsblk not installed)"
	else
		echo -e "${COL}${BOLD}Disks and Partitions:${RESET}"
		########First level lsblk tree
		NUM_DISKS=$(lsblk -ndo NAME | wc -l)
		for (( c=1; c<=NUM_DISKS; c++ ))		## Loop through output for each of the disks/partitions
		do

			WORKING_DEVICE=$(lsblk -idno NAME | sed -n "${c}p" | cut -d "-" -f 2-10)	## Define device name
			DEVICE_TYPE=$(lsblk -dno TYPE /dev/${WORKING_DEVICE})				## Define device type
			DEVICE_MODEL=$(lsblk -dno MODEL /dev/"${WORKING_DEVICE}")			## Define device model
			DEVICE_SIZE=$(lsblk -dno SIZE /dev/"${WORKING_DEVICE}")				## Define device capacity
			echo -e "${COL}--Device:${RESET} ${WORKING_DEVICE}"				## Print device name
			echo -e "${COL}${DIM}----Type:${RESET} ${DEVICE_TYPE}"				## Print device type
			if [ -n "${DEVICE_MODEL}" ]; then						## If data exists for disk model
				echo -e "${COL}${DIM}----Model:${RESET} ${DEVICE_MODEL}"		## Print device model
			fi
			echo -e "${COL}${DIM}----Size:${RESET} ${DEVICE_SIZE}"				## Print device size

			########Second level lsblk tree
			NUM_CHILDREN=$(lsblk -no NAME /dev/${WORKING_DEVICE} | wc -l)		## Count the number of children
			for (( d=2; d<=NUM_CHILDREN; d++ ))					## Start at 2 because NUM_CHILDREN included parent
			do
				WORKING_CHILD=$(lsblk -ino NAME /dev/${WORKING_DEVICE} | sed -n "${d}p" | cut -d "-" -f 2-10)	## Define the name
				if [ -e /dev/${WORKING_CHILD} ]; then
					CHILD_TYPE=$(lsblk -dno TYPE /dev/${WORKING_CHILD})			## Define the type
					CHILD_SIZE=$(lsblk -dno SIZE /dev/${WORKING_CHILD})			## Define size
					CHILD_PERC=$(df -lh | grep -m 1 "${WORKING_CHILD}" | awk '{print $5}')	## Define percentage utilisation
					CHILD_USED=$(df -lh | grep -m 1 "${WORKING_CHILD}" | awk '{print $3}')	## Define capacity utilisation
					CHILD_MOUNT=$(lsblk -dno MOUNTPOINT /dev/${WORKING_CHILD})		## Define mount location
					echo -e "${COL}----Child:${RESET} ${WORKING_CHILD}"			## Print name
					echo -e "${COL}${DIM}------Type:${RESET} ${CHILD_TYPE}"			## Print type
					echo -e "${COL}${DIM}------Size:${RESET} ${CHILD_SIZE}"			## Print size
					if [ -n "${CHILD_USED}" ]; then						## If data exists for utilisation
						echo -e "${COL}${DIM}------Utilisation:${RESET} ${CHILD_USED} (${CHILD_PERC})"	## Print utilization
					fi
					if [ -n "${CHILD_MOUNT}" ]; then					## If data exists for mountpoint
						echo -e "${COL}${DIM}------Mount:${RESET} ${CHILD_MOUNT}"	## Print mountpoint
					fi

					########Third level and beyond in lsblk tree
					NUM_GRANDCHILDREN=$(lsblk -no NAME /dev/${WORKING_CHILD} | wc -l)	## Count the number of grandchildren
					for (( e=2; e<=NUM_GRANDCHILDREN; e++ ))		## Start at 2 because NUM_GRANDCHILDREN included child
					do
						WORKING_GRANDCHILD=$(lsblk -ino NAME /dev/${WORKING_CHILD} | sed -n "${e}p" | cut -d "-" -f 2-10)	## Name
						GRANDCHILD_TYPE=$(lsblk -in /dev/${WORKING_CHILD} | sed -n "${e}p" | awk '{print $6}')			## Type
						GRANDCHILD_SIZE=$(lsblk -no SIZE /dev/${WORKING_CHILD} | sed -n "${e}p")				## Size
						GRANDCHILD_PERC=$(df -lh | grep -m 1 "${WORKING_GRANDCHILD}" | awk '{print $5}')	## Percentage used
						GRANDCHILD_USED=$(df -lh | grep -m 1 "${WORKING_GRANDCHILD}" | awk '{print $3}')	## Capacity used
						GRANDCHILD_MOUNT=$(lsblk -in /dev/${WORKING_CHILD} | sed -n "${e}p" | awk '{print $7}')	## Mountpoint
						echo -e "${COL}------Grandchild:${RESET} ${WORKING_GRANDCHILD}"		## Print name
						echo -e "${COL}${DIM}--------Type:${RESET} ${GRANDCHILD_TYPE}"		## Print type
						echo -e "${COL}${DIM}--------Size:${RESET} ${GRANDCHILD_SIZE}"		## Print size
						if [ -n "${GRANDCHILD_USED}" ]; then					## If data exists for utilisation
							echo -e "${COL}${DIM}--------Utilisation:${RESET} ${GRANDCHILD_USED} (${GRANDCHILD_PERC})"
						fi
						if [ -n "${GRANDCHILD_MOUNT}" ]; then					## If data exists for mountpoint
							echo -e "${COL}${DIM}--------Mount:${RESET} ${GRANDCHILD_MOUNT}"## Print the mountpoint
						fi
					done
				fi
			done
		done
	fi
fi

###############################################################################################################################################################
## Print OS kernel and distribution info
if [[ -n "$GET_O_OS_INFO" || -n "$GET_ALL_INFO" ]]; then
	echo -e "${COL}${BOLD}Operating System:${RESET}"
	echo -e "${COL}--OS:${RESET} $(uname -o)"			## Print OS
	echo -e "${COL}--Architecture:${RESET} $(uname -m)"		## Print machine
	echo -e "${COL}--Kernel:${RESET} $(uname -s)"			## Print kernel
	echo -e "${COL}${DIM}----Version:${RESET} $(uname -v)"		## Print kernel version
	echo -e "${COL}${DIM}----Release:${RESET} $(uname -r)"		## Print kernel release
	if ! command -v lsb_release >> /dev/null ; then			## If lsb_release not installed (send to /dev/null to suppress stdout)
		if [ ! -f /etc/os-release ]; then			## If file /etc/os-release does not exist
			echo -e "Cannot determine distribution information (lsb_release not installed and /etc/os-release not present)"
		else	## Determine distribution info by parsing contents of /etc/os-release
			echo -e "${COL}${DIM}--Distribution:${RESET} $(grep "^PRETTY_NAME=" /etc/os-release | cut -d "\"" -f 2)"	## Print distro
			echo -e "${COL}${DIM}----Version:${RESET} $(grep "^VERSION=" /etc/os-release | cut -d "\"" -f 2)"		## Print distro version
			echo -e "${COL}${DIM}----ID:${RESET} $(grep "^ID=" /etc/os-release | cut -d "=" -f 2)"				## Print distro ID
		fi
	else		## Determine distribution info by running command "lsb_release"
		echo -e "${COL}--Distribution:${RESET} $(lsb_release -i | cut -f2)"		## Print distro
		echo -e "${COL}${DIM}----Release:${RESET} $(lsb_release -r | cut -f2)"		## Print distro release
		echo -e "${COL}${DIM}----Codename:${RESET} $(lsb_release -c | cut -f2)"		## Print distro codename
	fi
fi

###############################################################################################################################################################
## Print network and network interface info
if [[ -n "$GET_N_NETWORK_INFO" || -n "$GET_ALL_INFO" ]]; then
	echo -e "${COL}${BOLD}Network:${RESET}"
	## Show external IP
	if ! command -v curl >> /dev/null ; then							## If curl not installed
		echo -e "Cannot determine external IP address (curl not installed)"			## Print a "no curl" error
	else
		EXT_IP=$(curl --silent --max-time 5 ipinfo.io | grep -m 1 "ip" | cut -d "\"" -f4)	## Grep external IP
		if [ -n "${EXT_IP}" ]; then								## If data exists for ext_ip
			echo -e "${COL}--External IP:${RESET} ${EXT_IP}"				## Print the external IP
		else											## Otherwise
			echo -e "${COL}--External IP:${RESET} No External Connection"			## Print no connection
		fi
	fi
	## Show primary dns address
	DNS=$(grep -m 1 "nameserver" /etc/resolv.conf | cut -d " " -f 2)	## Grep primary (first in list) DNS
	if [ -n "${DNS}" ]; then						## If data exists for DNS
		echo -e "${COL}--DNS:${RESET} ${DNS}"				## Print the DNS
	fi
	## Show default gateway address
	if ! command -v ip >> /dev/null ; then							## If ip not installed
		if ! command -v route >> /dev/null ; then					## If route not installed
			if ! command -v netstat >> /dev/null ; then				## If netstat not installed
				echo -e "Cannot determine default gateway address (neither ip nor route nor netstat installed)"
			else
				GW=$(netstat -r -n | grep -m 1 "0.0.0.0" | awk '{print $2}')	## Use netstat to determine the gateway
			fi
		else
			GW=$(route -n | grep -m 1 "0.0.0.0" | awk '{print $2}')			## Use route to determine the gateway
		fi
	else
		GW=$(ip route | grep -m 1 "default" | cut -d " " -f 3)				## Use ip to determine the gateway
	fi
	if [ -n "${GW}" ]; then									## If data exists for GW
		echo -e "${COL}--Gateway:${RESET} ${GW}"					## Print the gateway address
	fi
	## Get hostname
	echo -e "${COL}--Hostname:${RESET} $(uname -n)"
	## Get info for all network interface devices (physical and virtual)
	NUM_DEVS=$(find /sys/class/net -type l | wc -w)		## Determine the number of network interfaces.
	for (( c=1; c<=NUM_DEVS; c++ ))				## Run this loop for each interface.
	do
		WORKING_INTERFACE=$(find /sys/class/net -type l | sed "${c}q;d" | cut -d "/" -f 5)	## Select working interface from the list of interfaces
		STATUS=$(cat /sys/class/net/"${WORKING_INTERFACE}"/operstate)				## Status of interface up, down or unknown
		MAC=$(cat /sys/class/net/"${WORKING_INTERFACE}"/address)				## MAC address of the inteface.
		echo -e "${COL}--Interface:${RESET} ${WORKING_INTERFACE}"				## Print the interface name
		echo -e "${COL}${DIM}----Status:${RESET} ${STATUS}"					## Print interface status
		if [ -n "${MAC}" ]; then								## Check if a MAC address was found
			echo -e "${COL}${DIM}----MAC address:${RESET} ${MAC}"				## Print the interface MAC address
		fi

		## Check if the status of the inteface is "up" or "unkown" (not "down")
		if [ "${STATUS}" != "down" ]; then ## If so, print the designated IP address.
			if ! command -v ip >> /dev/null ; then				# If ip is not installed (send to /dev/null to suppress stdout)
				if ! command -v ifconfig >> /dev/null ; then		# If ifconfig is not installed (send to /dev/null to suppress stdout)
					echo -e "Cannot determine interface ip address (neither ip nor ifconfig installed)"
				else
					IP=$(ifconfig "${WORKING_INTERFACE}" | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1)	## Use ifconfig
				fi
			else
				IP=$(ip addr show "${WORKING_INTERFACE}" | grep -w -m1 "inet" | cut -d " " -f 6)			## Use ip
			fi
			if [ -n "${IP}" ]; then							## If an ip address was identified
				echo -e "${COL}${DIM}----IP address:${RESET} ${IP}"		## Print the IP address
			fi
		fi

		## Check if the current interface is connected to WIFI.  If so, show ESSID.
		if ! command -v iwgetid >> /dev/null ; then			## If iwgetid is not installed (send to /dev/null to suppress stdout)
			if ! command -v iw >> /dev/null ; then			## If iw is not installed (send to /dev/null to suppress stdout)
				if ! command -v nmcli >> /dev/null ; then	## If nmcli is not installed (send to /dev/null to suppress stdout)
					ESSID=""
				else
					ESSID=$(nmcli | grep "${WORKING_INTERFACE}: connected to" | cut -d " " -f 4)	## Use nmcli to determine ESSID
				fi
			else
				ESSID=$(iw dev "${WORKING_INTERFACE}" link | grep "SSID" | cut -d " " -f 2)		## Use iw to detemine ESSID
			fi
		else
			IF_WIFI_CONN=$(iwgetid | awk '{print $1}')				## Use iwgetid to determine ESSID
			if [ "${IF_WIFI_CONN}" == "${WORKING_INTERFACE}" ]; then		## If iwgetid shows that WORKING_INTERFACE has a connected ESSID
				ESSID=$(iwgetid -r)						## Then get the ESSID.
			else
				ESSID=""							## Needed in-case previous loop iteration sets ESSID
			fi
		fi
		if [ -n "${ESSID}" ] && [ "${ESSID}" != "Wired" ] ; then		## If an essid was found
			echo -e "${COL}${DIM}----Connected ESSID:${RESET} ${ESSID}"	## Print the ESSID
		fi
	done
fi

echo -e "${COL}==================${RESET}"
echo
exit 0
