#!/bin/bash

#BLACK="\033[00;30m"
#RED="\033[00;31m"
#GREEN="\033[00;32m"
#YELLOW="\033[00;33m"
#BLUE="\033[00;34m"
#MAGENTA="\033[00;35m"
CYAN="\033[00;36m"
#GRAY="\033[00;37m"
#WHITE="\033[01;37m"

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

## Set main heading colour from options above.
COL=${CYAN}

echo -e " "
echo -e "${COL}╔════════════════════╗${RESET}"
echo -e "${COL}║${RESET} ${BOLD}System Information ${RESET}${COL}║${RESET}"
echo -e "${COL}╚════════════════════╝${RESET}"

###############################
## Print available product info
if [ -s /sys/devices/virtual/dmi/id/product_name ]; then
	product_name=$(cat /sys/devices/virtual/dmi/id/product_name)
	product_version=$(cat /sys/devices/virtual/dmi/id/product_version)
	sys_vendor=$(cat /sys/devices/virtual/dmi/id/sys_vendor)
	if [ ! -z "${product_name}" ]; then
		if [ ! -z "${product_version}" ]; then
			if [ ! -z "${sys_vendor}" ]; then
				echo -e "${COL}${BOLD}Product:${RESET} $product_name, version $product_version ($sys_vendor)"
			else
				echo -e "${COL}${BOLD}Product:${RESET} $product_name, version $product_version"
			fi
		elif [ ! -z "${sys_vendor}" ]; then
			echo -e "${COL}${BOLD}Product:${RESET} $product_name ($sys_vendor)"
		else
			echo -e "${COL}${BOLD}Product:${RESET} $product_name"
		fi
	fi
else
        echo -e "Product information not found"
fi

###############################
## Print available chassis info
if [ -s /sys/devices/virtual/dmi/id/chassis_type ]; then
	chassis_type=$(cat /sys/devices/virtual/dmi/id/chassis_type)
	chassis_version=$(cat /sys/devices/virtual/dmi/id/chassis_version)
	chassis_vendor=$(cat /sys/devices/virtual/dmi/id/chassis_vendor)
	if [ ! -z "${chassis_type}" ]; then
        	if [ ! -z "${chassis_version}" ]; then
			if [ ! -z "${chassis_vendor}" ]; then
				echo -e "${COL}${BOLD}Chassis:${RESET} $chassis_type, version $chassis_version ($chassis_vendor)"	## Chassis type, version, vendor
			else
				echo -e "${COL}${BOLD}Chassis:${RESET} $chassis_type, version $chassis_version"			## Chassis type, version
			fi
		elif [ ! -z "${chassis_vendor}" ]; then
			echo -e "${COL}${BOLD}Chassis:${RESET} $chassis_type ($chassis_vendor)"					## Chassis type, vendor
		fi
        else
                echo -e "${COL}${BOLD}Chassis:${RESET} $chassis_type"								## Chassis type
        fi
else
	echo -e "Chassis information not found"
fi

###############################
## Print available motherboard info
if [ -s /sys/devices/virtual/dmi/id/board_name ]; then
	board_name=$(cat /sys/devices/virtual/dmi/id/board_name)
	board_version=$(cat /sys/devices/virtual/dmi/id/board_version)
	board_vendor=$(cat /sys/devices/virtual/dmi/id/board_vendor)
	if [ ! -z "${board_name}" ]; then
        	if [ ! -z "${board_version}" ]; then
			if [ ! -z "${board_vendor}" ]; then
				echo -e "${COL}${BOLD}Motherboard:${RESET} $board_name, version $board_version ($board_vendor)"    ## Motherboard model, version, vendor
			else
				echo -e "${COL}${BOLD}Motherboard:${RESET} $board_name, version $board_version"                    ## Motherboard model, version
			fi
		elif [ ! -z "${board_vendor}" ]; then
			echo -e "${COL}${BOLD}Motherboard:${RESET} $board_name ($board_vendor)"					## Motherboard name, vendor
		else
			echo -e "${COL}${BOLD}Motherboard:${RESET} $board_name"                                                    ## Motherboard model
		fi
        fi
else
	echo -e "Motherboard information not found"
fi

###############################
## Print available bios info
if [ -s /sys/devices/virtual/dmi/id/bios_date ]; then
	bios_date=$(cat /sys/devices/virtual/dmi/id/bios_date)
	bios_version=$(cat /sys/devices/virtual/dmi/id/bios_version)
	bios_vendor=$(cat /sys/devices/virtual/dmi/id/bios_vendor)
	if [ ! -z "${bios_date}" ]; then
		if [ ! -z "${bios_version}" ]; then
			if [ ! -z "${bios_vendor}" ]; then
				echo -e "${COL}${BOLD}Bios:${RESET} $bios_date, version $bios_version ($bios_vendor)"   	## Bios date, version, vendor
			else
				echo -e "${COL}${BOLD}Bios:${RESET} $bios_date, version $bios_version"                  	## Bios date, version
			fi
		elif [ ! -z "${bios_vendor}" ]; then
			echo -e "${COL}${BOLD}Bios:${RESET} $bios_date ($bios_vendor)"					## Bios date, vendor
		else
			echo -e "${COL}${BOLD}Bios:${RESET} $bios_date"                                                 	## Bios date
		fi
	fi
else
	echo -e "Bios information not found"
fi

###############################
## Print available CPU info
if ! which lscpu >> /dev/null ; then	#If lscpu not installed (send to /dev/null to suppress stdout)
	echo -e "Cannot determine cpu infomtion (lscpu not installed)"
else
	model=$(lscpu | grep "Model name:" | tail -c+24)
	arch=$(lscpu | grep "Architecture" | awk '{print $2}')
	mode=$(lscpu | grep "CPU op-mode" | tail -c+24)
	cores=$(lscpu | grep -m 1 "CPU(s)" | awk '{print $2}')
	speed=$(lscpu | grep "CPU MHz" | awk '{print $3}')
	max_speed=$(lscpu | grep "CPU max" | awk '{print $4}')
	min_speed=$(lscpu | grep "CPU min" | awk '{print $4}')
	echo -e "${COL}${BOLD}CPU:${RESET}"
	if [ ! -z "$model" ];		then echo -e "${COL}--Model:${RESET} ${model}"; fi		## CPUModel and vendor
	if [ ! -z "$arch" ];		then echo -e "${COL}--Architecture:${RESET} ${arch}"; fi	## Architecture
	if [ ! -z "$mode" ];		then echo -e "${COL}--Mode(s):${RESET} ${mode}"; fi		## CPU op-mode(s)
	if [ ! -z "$cores" ];		then echo -e "${COL}--Cores:${RESET} ${cores}"; fi		## CPU(s)
	if [ ! -z "$speed" ];		then echo -e "${COL}--Speed:${RESET} ${speed}MHz"; fi		## CPU MHz
	if [ ! -z "$max_speed" ];	then echo -e "${COL}--Max Speed:${RESET} ${max_speed}MHz"; fi	## Max CPU MHz
	if [ ! -z "$min_speed" ];	then echo -e "${COL}--Min Speed:${RESET} ${min_speed}MHz"; fi	## Min CPU MHz
fi

###############################
## Print memory info
echo -e "${COL}${BOLD}Memory:${RESET}"
echo -e "${COL}--RAM:${RESET}"
echo -e "${COL}${DIM}----Total:${RESET} $(free -h | grep "Mem:" | awk '{print $2}')"
echo -e "${COL}${DIM}----Used:${RESET}  $(free -h | grep "Mem:" | awk '{print $3}')"
echo -e "${COL}${DIM}----Free:${RESET}  $(free -h | grep "Mem:" | awk '{print $4}')"
echo -e "${COL}--SWAP:${RESET}"
echo -e "${COL}${DIM}----Total:${RESET} $(free -h | grep "Swap" | awk '{print $2}')"
echo -e "${COL}${DIM}----Used:${RESET}  $(free -h | grep "Swap" | awk '{print $3}')"
echo -e "${COL}${DIM}----Free:${RESET}  $(free -h | grep "Swap" | awk '{print $4}')"

###############################
## Print video and audio info (note only first result of each if multiple video or audio devices exist)
if ! which lspci >> /dev/null ; then		#If lspci not installed (send to /dev/null to suppress stdout)
	echo -e "Cannot determine video or audio information (lspci not installed)"
else
	video_info=$(lspci -k | grep -m 1 VGA | tail -c+36)
	if [ ! -z "${video_info}" ]; then
		echo -e "${COL}${BOLD}Video:${RESET} ${video_info}"		## Video info
	else
		echo -e "Video information not found"
	fi
	audio_info=$(lspci -k | grep -m 1 Audio | tail -c+23)
	if [ ! -z "${audio_info}" ]; then
		echo -e "${COL}${BOLD}Audio:${RESET} ${audio_info}"		## Audio info
	else
		echo -e "Audio information not found"
	fi
fi

###############################
## Print disk and partition info
if ! which lsblk >> /dev/null ; then	#If lsblk not installed (send to /dev/null to suppress stdout)
	echo -e "Cannot determine disk/partition information (lsblk not installed)"
else

	echo -e "${COL}${BOLD}Disks and Partitions:${RESET}"
	mapfile -t part_list < <(lsblk -lno NAME)	## Define a list of disks and partitions.
	for t in "${part_list[@]}"			## Cycle through loop once for each disk or partition.
		do
		type=$(lsblk -dno TYPE /dev/"$t")

	        # If type is "disk" (not partition)
	        if [ "$type" == "disk" ] || [ "$type" == "rom" ]; then
	                echo -e "${COL}--Disk:${RESET} $t"
	                disk_model=$(lsblk -dno MODEL /dev/"$t")  ## Define disk model
	                disk_size=$(lsblk -dno SIZE /dev/"$t")    ## Define disk capacity
			if [ "$disk_model" ]; then		## If data exists for disk model
				echo -e "${COL}${DIM}----Model:${RESET} $disk_model"
			fi
	                echo -e "${COL}${DIM}----Size:${RESET} $disk_size"
	        fi

	        # If type is "part" (not disk)
	        if [ "$type" == "part" ]; then
	                echo -e "${COL}----Partition:${RESET} $t"
	                part_size=$(lsblk -no SIZE /dev/"$t")             ## Define partition size
			if [ "$(lsblk -ln | grep -m 1 "$t" | awk '{print $7}')" == "/" ]; then	#if lsblk references "/dev/root" instead of corresponding "/dev/$t"
				part_perc=$(df -h | grep -m 1 "/dev/root" | awk '{print $5}') ## Define partition percentage utilisation of root dir
				part_used=$(df -h | grep -m 1 "/dev/root" | awk '{print $3}') ## Define partition capacity utilisation of root dir
			else
				part_perc=$(df -h | grep -m 1 "$t" | awk '{print $5}') ## Define partition percentage utilisation
				part_used=$(df -h | grep -m 1 "$t" | awk '{print $3}') ## Define partition capacity utilisation
			fi
	                part_mount=$(lsblk -no MOUNTPOINT /dev/"$t")      ## Define partition mount location
	                echo -e "${COL}${DIM}------Size:${RESET} $part_size"
	                if [ "$part_used" ]; then                         ## If data exists for partition utilisation
	                        echo -e "${COL}${DIM}------Utilisation:${RESET} $part_used ($part_perc)"
	                fi
			if [ "$part_mount" ]; then			## If data exists for partition mount location
				echo -e "${COL}${DIM}------Mount:${RESET} $part_mount"
			fi
	        fi
	done
fi

###############################
## Print OS kernel and distribution info
echo -e "${COL}${BOLD}Operating System:${RESET}"
echo -e "${COL}--OS:${RESET} $(uname -o)"
echo -e "${COL}--Machine:${RESET} $(uname -m)"
echo -e "${COL}--Kernel:${RESET} $(uname -s)"
echo -e "${COL}${DIM}----Version:${RESET} $(uname -v)"
echo -e "${COL}${DIM}----Release:${RESET} $(uname -r)"
if ! which lsb_release >> /dev/null ; then	#If lsb_release not installed (send to /dev/null to suppress stdout)
	echo -e "Cannot determine distribution information (lsb_release not installed)"
else
	echo -e "${COL}--Distribution:${RESET} $(lsb_release -i | cut -f2)" #tab is the default delimeter for cut
	echo -e "${COL}${DIM}----Release:${RESET} $(lsb_release -r | cut -f2)"
	echo -e "${COL}${DIM}----Codename:${RESET} $(lsb_release -c | cut -f2)"
fi

###############################
## Print network and network interface info
echo -e "${COL}${BOLD}Network:${RESET}"
if [ -e /usr/bin/curl ]; then	## Check to ensure that curl is installed
	ext_ip=$(curl --silent --max-time 5  ipinfo.io | grep -m 1 "ip" | cut -d "\"" -f4) ## Grep external IP.  Requires curl.
	if [ "$ext_ip" ]; then	## If data exists for ext_ip
		echo -e "${COL}--External IP:${RESET} $ext_ip"
	else
		echo -e "${COL}--External IP:${RESET} No External Connection"
	fi
else
	echo -e "External IP address not detected (curl not installed)"
fi
dns=$(grep -m 1 'nameserver' /etc/resolv.conf | cut -c12-)	## Grep primary (first in list) DNS
if [ "$dns" ]; then	## If data exists for DNS
	echo -e "${COL}--DNS:${RESET} $dns"
fi

echo -e "${COL}--Hostname:${RESET} $(uname -n)"

NUM_DEVS=$(ls /sys/class/net | wc -w)
for (( c=1; c<=$NUM_DEVS; c++ ))
do
	i=$(ls /sys/class/net | sed "${c}q;d")

        echo -e "${COL}--Interface:${RESET} $i"
        status=$(cat /sys/class/net/"${i}"/operstate)     ## Status of interface up, down or unknown.
        echo -e "${COL}${DIM}----Status:${RESET} $status"
        mac=$(cat /sys/class/net/"${i}"/address)       ## MAC address of the inteface.
	if [ ! -z "$mac" ]; then	#check if a MAC address was found
		echo -e "${COL}${DIM}----MAC address:${RESET} $mac"	#if so, print it
	fi
	
	## Check if the status of the inteface is "up" or "unkown" (not "down")
	if [ "$status" != "down" ]; then ## If so, print the designated IP address.
		if ! which ip >> /dev/null ; then			#If ip is not installed (send to /dev/null to suppress stdout)
			if ! which ifconfig >> /dev/null ; then		#If ifconfig is not installed (send to /dev/null to suppress stdout)
				echo -e "Cannot determine interface ip address (neither ip nor ifconfig installed)"
			else
				ip=$(ifconfig "${i}" | grep "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1)
			fi
		else
			ip=$(/bin/ip addr show "${i}" | grep -w -m1 "inet" | cut -d " " -f6)
		fi
		if [ ! -z "$ip" ]; then		#If an ip address was identified
			echo -e "${COL}${DIM}----IP address:${RESET} $ip"
		fi
	fi

	## Check if the current interface is connected to an essid
	if ! which iwgetid >> /dev/null ; then			#If iwgetid is not installed (send to /dev/null to suppress stdout)
		if ! which iw >> /dev/null ; then		#If iw is not installed (send to /dev/null to suppress stdout)
			echo -e "Unable to check for ESSID (neither iwgetid nor iw installed)"
		else
			essid=$(iw dev "${i}" link | grep "SSID" | cut -d " " -f 2)
			#echo -e "${COL}${DIM}----Connected ESSID:${RESET} $essid"
		fi
	else
		if_wifi_conn=$(/sbin/iwgetid | awk '{print $1}')
		if [ "$if_wifi_conn" = "${i}" ]; then   ## If so, print the connected essid.
			essid=$(/sbin/iwgetid -r)
			#echo -e "${COL}${DIM}----Connected ESSID:${RESET} $essid"
		fi
	fi
	if [ ! -z "$essid" ]; then	#If an essid was found
		echo -e "${COL}${DIM}----Connected ESSID:${RESET} $essid"
	fi
done

echo -e "${COL}==================${RESET}"
echo 

exit 0
