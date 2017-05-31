#!/bin/bash

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
DIM=$(tput dim)

RESET=$(tput sgr0)

## Set main heading colour from options above.
COL=${CYAN}

echo " "
echo "${COL}╔════════════════════╗${RESET}"
echo "${COL}║${RESET} ${BOLD}System Information ${RESET}${COL}║${RESET}"
echo "${COL}╚════════════════════╝${RESET}"

###############################
## Print available product info
if [ -s "/sys/devices/virtual/dmi/id/product_name" ]; then
        product_name=$(cat /sys/devices/virtual/dmi/id/product_name | awk NF)
	product_version=$(cat /sys/devices/virtual/dmi/id/product_version | awk NF)
	sys_vendor=$(cat /sys/devices/virtual/dmi/id/sys_vendor | awk NF)
	if [ ! -z "${product_name}" ]; then
		if [ ! -z "${product_version}" ]; then
			if [ ! -z "${sys_vendor}" ]; then
				echo "${BOLD}${COL}Product:${RESET} $product_name, version $product_version ($sys_vendor)"
			else
				echo "${BOLD}${COL}Product:${RESET} $product_name, version $product_version"
			fi
		elif [ ! -z "${sys_vendor}" ]; then
			echo "${BOLD}${COL}Product:${RESET} $product_name ($sys_vendor)"
		else
			echo "${BOLD}${COL}Product:${RESET} $product_name"
		fi
	fi
else
        echo "Product information not found"
fi

###############################
## Print available chassis info
if [ -s /sys/devices/virtual/dmi/id/chassis_type ]; then
	chassis_type=$(cat /sys/devices/virtual/dmi/id/chassis_type | awk NF)
	chassis_version=$(cat /sys/devices/virtual/dmi/id/chassis_version | awk NF)
	chassis_vendor=$(cat /sys/devices/virtual/dmi/id/chassis_vendor | awk NF)
	if [ ! -z "${chassis_type}" ]; then
        	if [ ! -z "${chassis_version}" ]; then
			if [ ! -z "${chassis_vendor}" ]; then
				echo "${BOLD}${COL}Chassis:${RESET} $chassis_type, version $chassis_version ($chassis_vendor)"	## Chassis type, version, vendor
			else
				echo "${BOLD}${COL}Chassis:${RESET} $chassis_type, version $chassis_version"			## Chassis type, version
			fi
		elif [ ! -z "${chassis_vendor}" ]; then
			echo "${BOLD}${COL}Chassis:${RESET} $chassis_type ($chassis_vendor)"					## Chassis type, vendor
		fi
        else
                echo "${BOLD}${COL}Chassis:${RESET} $chassis_type"								## Chassis type
        fi
else
	echo "Chassis information not found"
fi

###############################
## Print available motherboard info
if [ -s /sys/devices/virtual/dmi/id/board_name ]; then
	board_name=$(cat /sys/devices/virtual/dmi/id/board_name | awk NF)
	board_version=$(cat /sys/devices/virtual/dmi/id/board_version)
	board_vendor=$(cat /sys/devices/virtual/dmi/id/board_vendor)
	if [ ! -z "${board_name}" ]; then
        	if [ ! -z "${board_version}" ]; then
			if [ ! -z "${board_vendor}" ]; then
				echo "${BOLD}${COL}Motherboard:${RESET} $board_name, version $board_version ($board_vendor)"    ## Motherboard model, version, vendor
			else
				echo "${BOLD}${COL}Motherboard:${RESET} $board_name, version $board_version"                    ## Motherboard model, version
			fi
		elif [ ! -z "${board_vendor}" ]; then
			echo "${BOLD}${COL}Motherboard:${RESET} $board_name ($board_vendor)"					## Motherboard name, vendor
		else
			echo "${BOLD}${COL}Motherboard:${RESET} $board_name"                                                    ## Motherboard model
		fi
        fi
else
	echo "Motherboard information not found"
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
				echo "${BOLD}${COL}Bios:${RESET} $bios_date, version $bios_version ($bios_vendor)"   	## Bios date, version, vendor
			else
				echo "${BOLD}${COL}Bios:${RESET} $bios_date, version $bios_version"                  	## Bios date, version
			fi
		elif [ ! -z "${bios_vendor}"]; then
			echo "${BOLD}${COL}Bios:${RESET} $bios_date ($bios_vendor)"					## Bios date, vendor
		else
			echo "${BOLD}${COL}Bios:${RESET} $bios_date"                                                 	## Bios date
		fi
	fi
else
	echo "Bios information not found"
fi

###############################
## Print available CPU info
model=$(lscpu | grep "Model name:" | tail -c+24)
arch=$(lscpu | grep "Architecture" | awk '{print $2}')
mode=$(lscpu | grep "CPU op-mode" | tail -c+24)
cores=$(lscpu | grep -m 1 "CPU(s)" | awk '{print $2}')
speed=$(lscpu | grep "CPU MHz" | awk '{print $3}')
max_speed=$(lscpu | grep "CPU max" | awk '{print $4}')
min_speed=$(lscpu | grep "CPU min" | awk '{print $4}')
echo "${BOLD}${COL}CPU:${RESET}"
if [ ! -z "$model" ];		then echo "${COL}--Model:${RESET} ${model}"; fi			## CPUModel and vendor
if [ ! -z "$arch" ];		then echo "${COL}--Architecture:${RESET} ${arch}"; fi		## Architecture
if [ ! -z "$mode" ];		then echo "${COL}--Mode(s):${RESET} ${mode}"; fi		## CPU op-mode(s)
if [ ! -z "$cores" ];		then echo "${COL}--Cores:${RESET} ${cores}"; fi			## CPU(s)
if [ ! -z "$speed" ];		then echo "${COL}--Speed:${RESET} ${speed}MHz"; fi		## CPU MHz
if [ ! -z "$max_speed" ];	then echo "${COL}--Max Speed:${RESET} ${max_speed}MHz"; fi	## Max CPU MHz
if [ ! -z "$min_speed" ];	then echo "${COL}--Min Speed:${RESET} ${min_speed}MHz"; fi	## Min CPU MHz

###############################
## Print memory info
echo "${BOLD}${COL}Memory:${RESET}"
echo "${COL}--RAM:${RESET}"
echo "${DIM}${COL}----Total:${RESET} $(free -h | grep "Mem:" | awk '{print $2}')"
echo "${DIM}${COL}----Used:${RESET}  $(free -h | grep "Mem:" | awk '{print $3}')"
echo "${DIM}${COL}----Free:${RESET}  $(free -h | grep "Mem:" | awk '{print $4}')"
echo "${COL}--SWAP:${RESET}"
echo "${DIM}${COL}----Total:${RESET} $(free -h | grep "Swap" | awk '{print $2}')"
echo "${DIM}${COL}----Used:${RESET}  $(free -h | grep "Swap" | awk '{print $3}')"
echo "${DIM}${COL}----Free:${RESET}  $(free -h | grep "Swap" | awk '{print $4}')"

###############################
## Print video and audio info (note only first result of each if multiple video or audio devices exist)
if [ -e /usr/bin/lspci ]; then	## lspci needed to find information - check if it is installed
	video_info=$(lspci -k | grep -m 1 VGA | tail -c+36)
	if [ ! -z "${video_info}" ]; then
		echo "${BOLD}${COL}Video:${RESET} ${video_info}"		## Video info
	else
		echo "Video information not found"
	fi
	audio_info=$(lspci -k | grep -m 1 Audio | tail -c+23)
	if [ ! -z "${audio_info}" ]; then
		echo "${BOLD}${COL}Audio:${RESET} ${audio_info}"		## Audio info
	else
		echo "Audio information not found"
	fi
else
	echo "Video and Audio hardware information not found (lspci needed but pciutils not installed)"
fi

###############################
## Print disk and partition info
echo "${BOLD}${COL}Disks and Partitions:${RESET}"
part_list=( `lsblk -lno NAME `) ## Define a list of disks and partitions.
for t in "${part_list[@]}"      ## Cycle through loop once for each disk or partition.
do
        type=$(lsblk -dno TYPE /dev/$t)

        # If type is "disk" (not partition)
        if [ "$type" == "disk" ] || [ "$type" == "rom" ]; then
                echo "${COL}--Disk:${RESET} $t"
                disk_model=$(lsblk -dno MODEL /dev/$t)  ## Define disk model
                disk_size=$(lsblk -dno SIZE /dev/$t)    ## Define disk capacity
		if [ "$disk_model" ]; then		## If data exists for disk model
			echo "${DIM}${COL}----Model:${RESET} $disk_model"
		fi
                echo "${DIM}${COL}----Size:${RESET} $disk_size"
        fi

        # If type is "part" (not disk)
        if [ "$type" == "part" ]; then
                echo "${COL}----Partition:${RESET} $t"
                part_size=$(lsblk -no SIZE /dev/$t)             ## Define partition size
		if [ "$(lsblk -ln | grep -m 1 $t | awk '{print $7}')" == "/" ]; then	#if lsblk references "/dev/root" instead of corresponding "/dev/$t"
			part_perc=$(df -h | grep -m 1 "/dev/root" | awk '{print $5}') ## Define partition percentage utilisation of root dir
			part_used=$(df -h | grep -m 1 "/dev/root" | awk '{print $3}') ## Define partition capacity utilisation of root dir
		else
			part_perc=$(df -h | grep -m 1 $t | awk '{print $5}') ## Define partition percentage utilisation
			part_used=$(df -h | grep -m 1 $t | awk '{print $3}') ## Define partition capacity utilisation
		fi
                part_mount=$(lsblk -no MOUNTPOINT /dev/$t)      ## Define partition mount location
                echo "${DIM}${COL}------Size:${RESET} $part_size"
                if [ $part_used ]; then                         ## If data exists for partition utilisation
                        echo "${DIM}${COL}------Utilisation:${RESET} $part_used ($part_perc)"
                fi
		if [ $part_mount ]; then			## If data exists for partition mount location
			echo "${DIM}${COL}------Mount:${RESET} $part_mount"
		fi
        fi
done

###############################
## Print OS kernel and distribution info
echo "${BOLD}${COL}Operating System:${RESET}"
echo "${COL}--OS:${RESET} $(uname -o)"
echo "${COL}--Machine:${RESET} $(uname -m)"
echo "${COL}--Kernel:${RESET} $(uname -s)"
echo "${DIM}${COL}----Version:${RESET} $(uname -v)"
echo "${DIM}${COL}----Release:${RESET} $(uname -r)"
echo "${COL}--Distribution:${RESET} $(lsb_release -i | tail -c+17)"
echo "${DIM}${COL}----Release:${RESET} $(lsb_release -r | awk '{print $2}')"
echo "${DIM}${COL}----Codename:${RESET} $(lsb_release -c | awk '{print $2}')"

###############################
## Print network and network interface info
echo "${BOLD}${COL}Network:${RESET}"
if [ -e /usr/bin/curl ]; then	## Check to ensure that curl is installed
	ext_ip=$(curl --silent --max-time 5  ipinfo.io | grep -m 1 "ip" | cut -d ":" -f 2 | cut -d "\"" -f 2) ## Grep external IP.  Requires curl.
	if [ $ext_ip ]; then	## If data exists for ext_ip
		echo "${COL}--External IP:${RESET} $ext_ip"
	else
		echo "${COL}--External IP:${RESET} No External Connection"
	fi
else
	echo "External IP address not detected (curl not installed)"
fi
dns=$(cat /etc/resolv.conf | grep -m 1 'nameserver' | awk {'print $2'})	## Grep primary (first in list) DNS
if [ $dns ]; then	## If data exists for DNS
	echo "${COL}--DNS:${RESET} $dns"
fi
##echo "${COL}--DNS:${RESET} $(cat /etc/resolv.conf | grep -m 1 'nameserver' | awk {'print $2'})"         ## Grep primary (first in list) DNS
echo "${COL}--Hostname:${RESET} $(uname -n)"

if_list=( `ls /sys/class/net`)  ## Define a list of all the network interfaces.
for i in "${if_list[@]}"        ## Cycle through the following loop for each interface.
do
        echo "${COL}--Interface:${RESET} $i"
        status=$(cat /sys/class/net/${i}/operstate)     ## Status of interface up, down or unknown.
        echo "${DIM}${COL}----Status:${RESET} $status"
        mac=$(cat /sys/class/net/${i}/address)       ## MAC address of the inteface.
	if [ ! -z "$mac" ]; then	#check if a MAC address was found
		echo "${DIM}${COL}----MAC address:${RESET} $mac"	#if so, print it
	fi

        ## Check if the status of the inteface is "up" or "unkown" (not "down")
        if [ $status != "down" ]; then ## If so, print the designated IP address.
                ip=$(/sbin/ifconfig ${i} | grep -w 'inet' | awk '{print $2}')
		if [ $(echo $ip | grep 'addr') ]; then	#depending on the version of ifconfig, output may include 'addr:'
			ip=$(echo $ip | tail -c+6)	#if so, attenuate so string only includes ip address
		fi
		if [ $ip ]; then	## If after above processing, data actually exists for ip
			echo "${DIM}${COL}----IP address:${RESET} $ip"
		fi
        fi

        ## Check if the current interface is connected to an essid
	if [ -e /sbin/iwgetid ]; then   ## Check to ensure that iwgetid is installed.  If not, print nothing.
	        if_wifi_conn=$(/sbin/iwgetid | awk '{print $1}')
	        if [ "$if_wifi_conn" = "${i}" ]; then   ## If so, print the connected essid.
	                essid=$(/sbin/iwgetid -r)
	                echo "${DIM}${COL}----Connected ESSID:${RESET} $essid"
	        fi
	fi
done

echo "${COL}==================${RESET}"
echo 

exit 0
