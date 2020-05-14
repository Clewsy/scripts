#!/bin/bash

## Set main text colour.
#COL="\\033[00;30m"		#Theme colour: BLACK
#COL="\\033[00;31m"		#Theme colour: RED
#COL="\\033[00;38;5;214m"		#Theme colour: ORANGE
#COL="\\033[00;32m"		#Theme colour: GREEN
#COL="\\033[00;33m"		#Theme colour: YELLOW
#COL="\\033[00;34m"		#Theme colour: BLUE
#COL="\\033[00;35m"		#Theme colour: MAGENTA
COL="\\033[00;36m"		#Theme colour: CYAN
#COL="\\033[00;40m"		#Theme colour: GRAY
#COL="\\033[00;37m"		#Theme colour: WHITE

BOLD="\\033[1m"
DIM="\\033[2m"
RESET="\\033[0m"

## Exit codes.
SUCCESS=0
BAD_OPTION=1
BAD_ARGUMENT=2

USAGE="
Usage: $(basename "$0") [option]
Valid options:
-A	All info
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

while getopts 'Apcmavdonh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	OPTIONS="TRUE"					## Used to determine if a valid or invalid option was entered
	case "$OPTION" in
		A)	GET_ALL_INFO="TRUE" ;;		## Set ALL flag - same output as selecting no options.
		p)	GET_P_PRODUCT_INFO="TRUE" ;;	## Set P flag - product info (inc. motherboard, chassis, bios)
		c)	GET_C_CPU_INFO="TRUE" ;;	## Set C flag - cpu
		m)	GET_M_MEMORY_INFO="TRUE" ;;	## Set M flag - memory
		a)	GET_A_AUDIO_INFO="TRUE" ;;	## Set A flag - audio hardware
		v)	GET_V_VIDEO_INFO="TRUE" ;;	## Set V flag - video hardware
		d)	GET_D_DISKS_INFO="TRUE" ;;	## Set D flag - disks and partitions (inc. raid)
		o)	GET_O_OS_INFO="TRUE" ;;		## Set O flag - operating system (inc. kernel)
		n)	GET_N_NETWORK_INFO="TRUE" ;;	## Set N flag - network
		h)	echo -e "$USAGE"		## Print help (usage).
			exit $SUCCESS			## Exit successfully.
			;;
		?)
			echo -e "$USAGE"		## Invalid option, show usage.
			exit $BAD_OPTION		## Exit.
			;;
	esac
done
shift $((OPTIND -1))			## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

if [ -z "$OPTIONS" ]; then		## Check if no options were entered.
	GET_ALL_INFO="TRUE"		## If so, set the ALL flag.
fi

if (( $# > 0 )); then			## Check if an argument was entered.
	echo -e "Invalid argument."	## If so, show usage and exit.
	echo -e "$USAGE"
	exit $BAD_ARGUMENT
fi

echo -e "\n${COL}${BOLD}╔════════════════════╗${RESET}"
echo -e "${COL}${BOLD}║${RESET} ${BOLD}System Information ${RESET}${COL}${BOLD}║${RESET}"
echo -e "${COL}${BOLD}╚════════════════════╝${RESET}"

###############################################################################################################################################################
## Print available product, chassis, motherboard, bios info
if [[ -n "$GET_P_PRODUCT_INFO" || -n "$GET_ALL_INFO" ]]; then

	echo -e "${COL}${BOLD}Product Info:${RESET}"

	###############################
	## Print available product info
	if [ -s /sys/devices/virtual/dmi/id/product_name ]; then
		PRODUCT_NAME=$(cat /sys/devices/virtual/dmi/id/product_name)
		PRODUCT_VERSION=$(cat /sys/devices/virtual/dmi/id/product_version)
		SYS_VENDOR=$(cat /sys/devices/virtual/dmi/id/sys_vendor)
		if [ -n "${PRODUCT_NAME}" ]; then
			if [ -n "${PRODUCT_VERSION}" ]; then
				if [ -n "${SYS_VENDOR}" ]; then
					echo -e "${COL}${BOLD}├─Product:${RESET} ${PRODUCT_NAME}, version ${PRODUCT_VERSION} (${SYS_VENDOR})"
				else
					echo -e "${COL}${BOLD}├─Product:${RESET} ${PRODUCT_NAME}, version ${PRODUCT_VERSION}"
				fi
			elif [ -n "${SYS_VENDOR}" ]; then
				echo -e "${COL}${BOLD}├─Product:${RESET} ${PRODUCT_NAME} (${SYS_VENDOR})"
			else
				echo -e "${COL}${BOLD}├─Product:${RESET} ${PRODUCT_NAME}"
			fi
		fi
	else
		echo -e "${COL}${BOLD}├─Product:${RESET} Information not found"
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
					echo -e "${COL}${BOLD}├─Chassis:${RESET} ${CHASSIS_TYPE}, version ${CHASSIS_VERSION} (${CHASSIS_VENDOR})"	## Chassis type, version, vendor
				else
					echo -e "${COL}${BOLD}├─Chassis:${RESET} ${CHASSIS_TYPE}, version ${CHASSIS_VERSION}"			## Chassis type, version
				fi
			elif [ -n "${CHASSIS_VENDOR}" ]; then
				echo -e "${COL}${BOLD}├─Chassis:${RESET} ${CHASSIS_TYPE} (${CHASSIS_VENDOR})"					## Chassis type, vendor
			fi
		else
			echo -e "${COL}${BOLD}├─Chassis:${RESET} ${CHASSIS_TYPE}"								## Chassis type
		fi
	else
		echo -e "${COL}${BOLD}├─Chassis:${RESET} Information not found"
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
					echo -e "${COL}${BOLD}├─Motherboard:${RESET} ${BOARD_NAME}, version ${BOARD_VERSION} (${BOARD_VENDOR})"	## Motherboard model, version, vendor
				else
					echo -e "${COL}${BOLD}├─Motherboard:${RESET} ${BOARD_NAME}, version ${BOARD_VERSION}"			## Motherboard model, version
				fi
			elif [ -n "${BOARD_VENDOR}" ]; then
				echo -e "${COL}${BOLD}├─Motherboard:${RESET} ${BOARD_NAME} (${BOARD_VENDOR})"					## Motherboard name, vendor
			else
				echo -e "${COL}${BOLD}├─Motherboard:${RESET} ${BOARD_NAME}"							## Motherboard model
			fi
		fi
	else
		echo -e "${COL}${BOLD}├─Motherboard:${RESET} Information not found"
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
					echo -e "${COL}${BOLD}└─Bios:${RESET} ${BIOS_DATE}, version ${BIOS_VERSION} (${BIOS_VENDOR})"	## Bios date, version, vendor
				else
					echo -e "${COL}${BOLD}└─Bios:${RESET} ${BIOS_DATE}, version ${BIOS_VERSION}"			## Bios date, version
				fi
			elif [ -n "${BIOS_VENDOR}" ]; then
				echo -e "${COL}${BOLD}└─Bios:${RESET} ${BIOS_DATE} (${BIOS_VENDOR})"					## Bios date, vendor
			else
				echo -e "${COL}${BOLD}└─Bios:${RESET} ${BIOS_DATE}"							## Bios date
			fi
		fi
	else
		echo -e "${COL}${BOLD}└─BIOS:${RESET} Information not found"
	fi
fi

###############################################################################################################################################################
## Print available CPU info
if [[ -n "$GET_C_CPU_INFO" || -n "$GET_ALL_INFO" ]]; then
	if ! command -v lscpu >> /dev/null ; then	## If lscpu not installed (send to /dev/null to suppress stdout)
		echo -e "${COL}${BOLD}CPU:${RESET} Cannot determine cpu infomtion (lscpu not installed)"
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
		if [ -n "${CPU_MODEL}" ];	then	echo -e "${COL}${BOLD}├─Model:${RESET} ${CPU_MODEL}"; fi		## CPUModel and vendor
		if [ -n "${CPU_VENDOR}" ];	then	echo -e "${COL}${BOLD}├─Vendor:${RESET} ${CPU_VENDOR}"; fi		## CPUModel and vendor
		if [ -n "${CPU_ARCH}" ];	then	echo -e "${COL}${BOLD}├─Architecture:${RESET} ${CPU_ARCH}"; fi		## Architecture
		if [ -n "${CPU_MODE}" ];	then	echo -e "${COL}${BOLD}├─Mode(s):${RESET} ${CPU_MODE}"; fi		## CPU op-mode(s)
		if [ -n "${CPU_CORES}" ];	then	echo -e "${COL}${BOLD}├─Cores:${RESET} ${CPU_CORES}"; fi		## CPU(s)
		if [ -n "${CPU_SPEED}" ];	then	echo -e "${COL}${BOLD}└─Speed:${RESET} ${CPU_SPEED}MHz"			## CPU Speed
		else					echo -e "${COL}${BOLD}└─Speed"; fi
		if [ -n "${CPU_MAX_SPEED}" ] && [ -n "${CPU_MIN_SPEED}" ]; then
			echo -e "${COL}  ├─Max:${RESET} ${CPU_MAX_SPEED}MHz"; 							## Max CPU MHz
			echo -e "${COL}  └─Min:${RESET} ${CPU_MIN_SPEED}MHz";							## Min CPU MHz
		else
			if [ -n "${CPU_MAX_SPEED}" ];	then	echo -e "${COL}  └─Max:${RESET} ${CPU_MAX_SPEED}MHz"; fi	## Max CPU MHz
			if [ -n "${CPU_MIN_SPEED}" ];	then	echo -e "${COL}  └─Min:${RESET} ${CPU_MIN_SPEED}MHz"; fi	## Min CPU MHz
		fi
	fi
fi

###############################################################################################################################################################
## Print memory info
if [[ -n "$GET_M_MEMORY_INFO" || -n "$GET_ALL_INFO" ]]; then
	echo -e "${COL}${BOLD}Memory:${RESET}"
	echo -e "${COL}${BOLD}├─RAM:${RESET}"
	echo -e "${COL}${BOLD}│ ${RESET}${COL}├─Total:    ${RESET} $(free -h | grep "Mem:" | awk '{print $2}')"	## Print total physical RAM
	echo -e "${COL}${BOLD}│ ${RESET}${COL}├─Used:     ${RESET} $(free -h | grep "Mem:" | awk '{print $3}')"	## Print used physical RAM
	echo -e "${COL}${BOLD}│ ${RESET}${COL}└─Available:${RESET} $(free -h | grep "Mem:" | awk '{print $7}')"	## Print available physical RAM
	echo -e "${COL}${BOLD}└─SWAP:${RESET}"
	echo -e "${COL}  ├─Total:    ${RESET} $(free -h | grep "Swap" | awk '{print $2}')"	## Print total allocated swap file size
	echo -e "${COL}  ├─Used:     ${RESET} $(free -h | grep "Swap" | awk '{print $3}')"	## Print used swap file size
	echo -e "${COL}  └─Free:     ${RESET} $(free -h | grep "Swap" | awk '{print $4}')"	## Print free swap file size
fi

###############################################################################################################################################################
## Print audio and video info (note only first result of each if multiple video or audio devices exist)
if [[ -n "$GET_A_AUDIO_INFO" || -n "$GET_V_VIDEO_INFO" || -n "$GET_ALL_INFO" ]]; then
	if ! command -v lspci >> /dev/null || ! lspci &> /dev/null; then		#If lspci not installed or fails (send to /dev/null to suppress stdout)
		echo -e "${COL}${BOLD}Audio/Video:${RESET} Cannot determine audio or video information (lspci not installed or failed)"
	else
		if [[ -n "$GET_ALL_INFO" || ( -n "$GET_A_AUDIO_INFO" && -n "$GET_V_VIDEO_INFO" ) ]]; then	## If we want both audio and vie info
			AUDIO_INFO=$(lspci -k | grep -m 1 Audio | cut -c23-)
			VIDEO_INFO=$(lspci -k | grep -m 1 VGA | cut -c36-)
			if xrandr &> /dev/null; then VIDEO_RES=$(xrandr --current | grep "current" | cut -d " " -f 8-10 | sed 's/.$//' &> /dev/null); fi
			if [ -z "${AUDIO_INFO}" ]; then AUDIO_INFO="Information not found"; fi
			if [ -z "${VIDEO_INFO}" ]; then VIDEO_INFO="Information not found"; fi
			echo -e "${COL}${BOLD}Audio/Video:${RESET}"
			echo -e "${COL}${BOLD}├─Audio Hardware:${RESET} ${AUDIO_INFO}"	## Audio info
			echo -e "${COL}${BOLD}└─Video Hardware:${RESET} ${VIDEO_INFO}"	## Video info
			if [ -n "${VIDEO_RES}" ]; then echo -e "${COL}  └─Resolution:${RESET} ${VIDEO_RES}"; fi	## Primary display resolution.
		elif [ -n "$GET_A_AUDIO_INFO" ]; then						## If we just want audio info
			AUDIO_INFO=$(lspci -k | grep -m 1 Audio | cut -c23-)
			if [ -z "${AUDIO_INFO}" ]; then AUDIO_INFO="Information not found"; fi
			echo -e "${COL}${BOLD}Audio:${RESET}"
			echo -e "${COL}${BOLD}└─Hardware:${RESET} ${AUDIO_INFO}"	## Audio info
		elif [ -n "$GET_V_VIDEO_INFO" ]; then						## If we just want video info
			VIDEO_INFO=$(lspci -k | grep -m 1 VGA | cut -c36-)
			if xrandr &> /dev/null; then VIDEO_RES=$(xrandr --current | grep "current" | cut -d " " -f 8-10 | sed 's/.$//' &> /dev/null); fi
			if [ -z "${VIDEO_INFO}" ]; then VIDEO_INFO="Information not found"; fi
			echo -e "${COL}${BOLD}Video:${RESET}"
			echo -e "${COL}${BOLD}└─Hardware:${RESET} ${VIDEO_INFO}"	## Video info
			if [ -n "${VIDEO_RES}" ]; then echo -e "${COL}  └─Resolution:${RESET} ${VIDEO_RES}"; fi	## Primary display resolution.
		fi
	fi
fi

###############################################################################################################################################################
## Print disk and partition info
if [[ -n "$GET_D_DISKS_INFO" || -n "$GET_ALL_INFO" ]]; then
	if	! command -v lsblk >> /dev/null; then	echo -e "${COL}${BOLD}Disks:${RESET} Cannot determine disk/partition information (lsblk not installed)."	## lsblk not installed.
	elif	! lsblk &> /dev/null; then		echo -e "${COL}${BOLD}Disks:${RESET} Cannot determine disk/partition information (lsblk returns error)."	## lsblk errors out.
	else						echo -e "${COL}${BOLD}Disks and Partitions:${RESET}"								## lsblk ok, continue.

		########First level lsblk tree
		NUM_DISKS=$(lsblk -ndo NAME | wc -l)
		for (( c=1; c<=NUM_DISKS; c++ ))		## Loop through output for each of the disks/partitions
		do
			WORKING_DEVICE=$(lsblk -idno NAME | sed -n "${c}p" | cut -d "-" -f 2-10)	## Define device name
			if [ "$(lsblk -dno TYPE /dev/"${WORKING_DEVICE}")" = "loop" ]; then continue; fi	## Skip output if it's a "loop" (created by a snap install).

			if (( c==(NUM_DISKS) )); then	## Last device in the list.
				echo -e "${COL}${BOLD}└─Device:${RESET} ${WORKING_DEVICE}"	## Print name
				C1="${COL}${BOLD}  ${RESET}"
			else
				echo -e "${COL}${BOLD}├─Device:${RESET} ${WORKING_DEVICE}"	## Print name
				C1="${COL}${BOLD}│ ${RESET}"
			fi

			NUM_CHILDREN=$(lsblk -no NAME /dev/"${WORKING_DEVICE}" | wc -l)		## Count the number of children
			DEVICE_TYPE=$(lsblk -dno TYPE /dev/"${WORKING_DEVICE}")			## Define device type
			DEVICE_MODEL=$(lsblk -dno MODEL /dev/"${WORKING_DEVICE}")		## Define device model
			DEVICE_SIZE=$(lsblk -dno SIZE /dev/"${WORKING_DEVICE}")			## Define device capacity

			DEV_SPECS=()											## Clear then reset the array of device specs 
			if [ -n "${DEVICE_TYPE}" ];	then DEV_SPECS+=("${COL}Type:${RESET} ${DEVICE_TYPE}"); fi
			if [ -n "${DEVICE_MODEL}" ];	then DEV_SPECS+=("${COL}Model:${RESET} ${DEVICE_MODEL}"); fi
			if [ -n "${DEVICE_SIZE}" ];	then DEV_SPECS+=("${COL}Size:${RESET} ${DEVICE_SIZE}"); fi

			for (( dspec=0; dspec<${#DEV_SPECS[@]}; dspec++ ))								## Loop for each device spec
			do
				if (( dspec==(${#DEV_SPECS[@]}-1) )) && (( NUM_CHILDREN==1 )); then	C2="${COL}└─${RESET}"		## If it's the last spec for the device (and no children)
				else									C2="${COL}├─${RESET}"; fi

				echo -e "${C1}${C2}${DEV_SPECS[dspec]}"									## Print the spec
			done

			########Second level lsblk tree
			for (( d=2; d<=NUM_CHILDREN; d++ ))					## Start at 2 because NUM_CHILDREN included parent
			do
				WORKING_CHILD=$(lsblk -ino NAME /dev/"${WORKING_DEVICE}" | sed -n "${d}p" | cut -d "-" -f 2-10)	## Define the name

				if [ -e /dev/"${WORKING_CHILD}" ]; then		## Only proceed for this "working_child" if it is recognised as a discrete device

					NUM_GRANDCHILDREN=$(lsblk -no NAME /dev/"${WORKING_CHILD}" | wc -l)	## Count the number of grandchildren

					if (( d==(NUM_CHILDREN-(NUM_GRANDCHILDREN-1)) )); then			## If it's the last child for this device.
						echo -e "${C1}${COL}└─Child:${RESET} ${WORKING_CHILD}"		## Print name
						C2="${COL}  ${RESET}"
					else
						echo -e "${C1}${COL}├─Child:${RESET} ${WORKING_CHILD}"		## Print name
						C2="${COL}│ ${RESET}"
					fi

					CHILD_TYPE=$(lsblk -dno TYPE /dev/"${WORKING_CHILD}")			## Define the type
					CHILD_SIZE=$(lsblk -dno SIZE /dev/"${WORKING_CHILD}")			## Define size
					CHILD_USED=$(df -lh | grep -m 1 "${WORKING_CHILD}" | awk '{print $3}')	## Define capacity utilisation
					CHILD_PERC=$(df -lh | grep -m 1 "${WORKING_CHILD}" | awk '{print $5}')	## Define percentage utilisation
					CHILD_MOUNT=$(lsblk -dno MOUNTPOINT /dev/"${WORKING_CHILD}")		## Define mount location

					CHILD_SPECS=()													## Clear then reset the array of child specs
					if [ -n "${CHILD_TYPE}" ];	then CHILD_SPECS+=("${COL}${DIM}Type:${RESET} ${CHILD_TYPE}"); fi
					if [ -n "${CHILD_SIZE}" ];	then CHILD_SPECS+=("${COL}${DIM}Size:${RESET} ${CHILD_SIZE}"); fi
					if [ -n "${CHILD_USED}" ];	then CHILD_SPECS+=("${COL}${DIM}Usage:${RESET} ${CHILD_USED} (${CHILD_PERC})"); fi
					if [ -n "${CHILD_MOUNT}" ];	then CHILD_SPECS+=("${COL}${DIM}Mount:${RESET} ${CHILD_MOUNT}"); fi

					for (( cspec=0; cspec<${#CHILD_SPECS[@]}; cspec++ ))									## Loop for all child specs
					do
						if (( cspec==(${#CHILD_SPECS[@]}-1) )) && (( NUM_GRANDCHILDREN==1 )); then	C3="${COL}${DIM}└─${RESET}"	## If it's the last child spec
						else										C3="${COL}${DIM}├─${RESET}"; fi

						echo -e "${C1}${C2}${C3}${CHILD_SPECS[cspec]}"									## Print the spec
					done

					########Third level and beyond in lsblk tree
					for (( e=2; e<=NUM_GRANDCHILDREN; e++ ))		## Start at 2 because NUM_GRANDCHILDREN included child
					do
						WORKING_GRANDCHILD=$(lsblk -ino NAME /dev/"${WORKING_CHILD}" | sed -n "${e}p" | cut -d "-" -f 2-10)

						if (( e==NUM_GRANDCHILDREN )); then							## Last grandchild for this child.
							echo -e "${C1}${C2}${COL}${DIM}└─Grandchild:${RESET} ${WORKING_GRANDCHILD}"	## Print name
							C3="${COL}${DIM}  ${RESET}"
						else
							echo -e "${C1}${C2}${COL}${DIM}├─Grandchild:${RESET} ${WORKING_GRANDCHILD}"	## Print name
							C3="${COL}${DIM}│ ${RESET}"
						fi
	
						GRANDCHILD_TYPE=$(lsblk -in /dev/"${WORKING_CHILD}" | sed -n "${e}p" | awk '{print $6}')	## Type
						GRANDCHILD_SIZE=$(lsblk -no SIZE /dev/"${WORKING_CHILD}" | sed -n "${e}p")		## Size
						GRANDCHILD_USED=$(df -lh | grep -m 1 "${WORKING_GRANDCHILD}" | awk '{print $3}')	## Capacity used
						GRANDCHILD_PERC=$(df -lh | grep -m 1 "${WORKING_GRANDCHILD}" | awk '{print $5}')	## Percentage used
						GRANDCHILD_MOUNT=$(lsblk -in /dev/"${WORKING_CHILD}" | sed -n "${e}p" | awk '{print $7}')	## Mountpoint

						GRANDCHILD_SPECS=()									## Clear then reset the array of child specs
						if [ -n "${GRANDCHILD_TYPE}" ];		then GRANDCHILD_SPECS+=("${COL}${DIM}Type:${RESET} ${GRANDCHILD_TYPE}"); fi
						if [ -n "${GRANDCHILD_SIZE}" ];		then GRANDCHILD_SPECS+=("${COL}${DIM}Size:${RESET} ${GRANDCHILD_SIZE}"); fi
						if [ -n "${GRANDCHILD_USED}" ];		then GRANDCHILD_SPECS+=("${COL}${DIM}Usage:${RESET} ${GRANDCHILD_USED} (${GRANDCHILD_PERC})"); fi
						if [ -n "${GRANDCHILD_MOUNT}" ];	then GRANDCHILD_SPECS+=("${COL}${DIM}Mount:${RESET} ${GRANDCHILD_MOUNT}"); fi

						for (( gcspec=0; gcspec<${#GRANDCHILD_SPECS[@]}; gcspec++ ))					## Loop for ech grandchild spec
						do
							if (( gcspec==(${#GRANDCHILD_SPECS[@]}-1) )); then	C4="${COL}${DIM}└─${RESET}"	## If last spec in array
							else							C4="${COL}${DIM}├─${RESET}"; fi

							echo -e "${C1}${C2}${C3}${C4}${GRANDCHILD_SPECS[gcspec]}"				## Print the spec
						done
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
	echo -e "${COL}${BOLD}├─OS:${RESET} $(uname -o)"			## Print OS
	echo -e "${COL}${BOLD}├─Architecture:${RESET} $(uname -m)"		## Print machine
	echo -e "${COL}${BOLD}├─Kernel:${RESET} $(uname -s)"			## Print kernel
	echo -e "${COL}${BOLD}│ ${RESET}${COL}├─Version:${RESET} $(uname -v)"	## Print kernel version
	echo -e "${COL}${BOLD}│ ${RESET}${COL}└─Release:${RESET} $(uname -r)"	## Print kernel release
	if ! command -v lsb_release >> /dev/null ; then			## If lsb_release not installed (send to /dev/null to suppress stdout)
		if [ ! -f /etc/os-release ]; then			## If file /etc/os-release does not exist
			echo -e "${COL}${BOLD}└─Distribution: ${RESET}Cannot determine distribution information (no lsb_release or /etc/os-release)"
		else	## Determine distribution info by parsing contents of /etc/os-release
			echo -e "${COL}${BOLD}└─Distribution:${RESET} $(grep "^PRETTY_NAME=" /etc/os-release | cut -d "\"" -f 2)"	## Print distro
			echo -e "${COL}  ├─Version:${RESET} $(grep "^VERSION=" /etc/os-release | cut -d "\"" -f 2)"	## Print distro version
			echo -e "${COL}  └─ID:${RESET} $(grep "^ID=" /etc/os-release | cut -d "=" -f 2)"			## Print distro ID
		fi
	else		## Determine distribution info by running command "lsb_release" (preferred)
		echo -e "${COL}${BOLD}└─Distribution:${RESET} $(lsb_release -i | cut -f2)"		## Print distro
		echo -e "${COL}  ├─Release:${RESET} $(lsb_release -r | cut -f2)"		## Print distro release
		echo -e "${COL}  └─Codename:${RESET} $(lsb_release -c | cut -f2)"		## Print distro codename
	fi
fi

###############################################################################################################################################################
## Print network and network interface info
if [[ -n "$GET_N_NETWORK_INFO" || -n "$GET_ALL_INFO" ]]; then
	echo -e "${COL}${BOLD}Network:${RESET}"

	## Show external IP
	if ! command -v curl >> /dev/null ; then					## If curl not installed
		EXT_IP="Cannot determine - curl not installed."				## Print a "no curl" error
	else
		EXT_IP=$(curl --silent --max-time 5 https://ipecho.net/plain)		## Determine external IP
		if [ -z "${EXT_IP}" ]; then EXT_IP="No External Connection"; fi		## If no data exists for ext_ip, create error message.
		echo -e "${COL}${BOLD}├─External IP:${RESET} ${EXT_IP}"			## Print EXT_IP
	fi

	## Show primary dns address
	if command -v nmcli >> /dev/null ; then	DNS=$(nmcli dev show | grep -m 1 "DNS" | tr -s " " | cut -d " " -f 2)	## Preferably determine DNS using nmcli command
	elif [ -f /etc/resolv.conf ] ; then	DNS=$(grep -m 1 "nameserver" /etc/resolv.conf | cut -d " " -f 2)	## Alternatively grep first DNS from resolv.conf
	else					DNS="Not found (no nmcli and no /etc/resolve.conf)." ; fi


	if [ -n "${DNS}" ]; then echo -e "${COL}${BOLD}├─DNS:${RESET} ${DNS}"; fi	## If data exists for DNS

	## Show default gateway address
	if ! command -v ip >> /dev/null ; then							## If ip not installed
		if ! command -v route >> /dev/null ; then					## If route not installed
			if ! command -v netstat >> /dev/null ; then				## If netstat not installed
				GW="Cannot determine default gateway address (ip nor route nor netstat installed)"
			else
				GW=$(netstat -r -n | grep -m 1 "0.0.0.0" | awk '{print $2}')	## Use netstat to determine the gateway
			fi
		else
			GW=$(route -n | grep -m 1 "0.0.0.0" | awk '{print $2}')			## Use route to determine the gateway
		fi
	else
		GW=$(ip route | grep -m 1 "default" | cut -d " " -f 3)				## Use ip to determine the gateway
	fi
	if [ "${GW}" = "" ]; then GW="Could not detect gateway."; fi
	echo -e "${COL}${BOLD}├─Gateway:${RESET} ${GW}"						## Print the gateway address

	## Get hostname
	echo -e "${COL}${BOLD}├─Hostname:${RESET} $(uname -n)"

	## Get info for all network interface devices (physical and virtual)
	if ! find /sys/class/net &> /dev/null ; then echo -e "${COL}${BOLD}└─Interface:${RESET} Cannot detect interfaces (no /sys/class/net/)."
	else

		NUM_DEVS=$(find /sys/class/net -type l | wc -w)		## Determine the number of network interfaces.
		for (( c=1; c<=NUM_DEVS; c++ ))				## Run this loop for each interface.
		do
			WORKING_INTERFACE=$(find /sys/class/net -type l | sed "${c}q;d" | cut -d "/" -f 5)				## Select working interface from the list of interfaces
			if [ -e /sys/class/net/${WORKING_INTERFACE}/operstate ]; then	STATUS=$(cat /sys/class/net/"${WORKING_INTERFACE}"/operstate)		## Status up, down or unknown
			else								STATUS="unknown"; fi
			MAC=$(cat /sys/class/net/"${WORKING_INTERFACE}"/address)										## MAC address of the inteface.

			if (( c==NUM_DEVS )); then	echo -e "${COL}${BOLD}└─Interface:${RESET} ${WORKING_INTERFACE}" && C1="${COL}${BOLD}  ${RESET}"	## If it's the last interfac
			else				echo -e "${COL}${BOLD}├─Interface:${RESET} ${WORKING_INTERFACE}" && C1="${COL}${BOLD}│ ${RESET}"; fi

			## Determine the IP address assigned o the interface
			## Check if the status of the inteface is "up" or "unkown" (not "down")
			if [ "${STATUS}" != "down" ]; then ## If so, print the designated IP address.
				if ! command -v ip >> /dev/null ; then				# If ip is not installed (send to /dev/null to suppress stdout)
					if ! command -v ifconfig >> /dev/null ; then		# If ifconfig is not installed (send to /dev/null to suppress stdout)
						IP="Cannot determine interface ip address (neither ip nor ifconfig installed)"
					else
						IP=$(ifconfig "${WORKING_INTERFACE}" | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1)	## Use ifconfig
					fi
				else
					IP=$(ip addr show "${WORKING_INTERFACE}" | grep -w -m1 "inet" | cut -d " " -f 6)			## Use ip
				fi
			fi

			## Determine the connected ESSID (if present)
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
			if [ "${ESSID}" == "Wired" ] ; then ESSID=""; fi		## If an essid was found

			## Clear and then set the array of interface specs
			INT_SPECS=()
			if [ -n "${STATUS}" ]; then	INT_SPECS+=("${COL}Status:${RESET} ${STATUS}"); fi
			if [ -n "${MAC}" ]; then 	INT_SPECS+=("${COL}Mac Address:${RESET} ${MAC}"); fi
			if [ -n "${IP}" ]; then		INT_SPECS+=("${COL}IP Address:${RESET} ${IP}"); fi
			if [ -n "${ESSID}" ]; then	INT_SPECS+=("${COL}Connected ESSID:${RESET} ${ESSID}"); fi

			## Print out each of the identified specifications for the current inteface
			for (( icspec=0; icspec<${#INT_SPECS[@]}; icspec++ ))					## Loop for ech grandchild spec
			do
				if (( icspec==(${#INT_SPECS[@]}-1) )); then	C2="${COL}└─${RESET}"	## If last spec in array
				else						C2="${COL}├─${RESET}"; fi
				echo -e "${C1}${C2}${INT_SPECS[icspec]}"				## Print the spec
			done
		done
	fi
fi

echo -e "${COL}${BOLD}──────────────────────────────────────────────────${RESET}\n"
