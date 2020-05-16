#!/bin/bash

## Just show the logo and some basic system info.

## Define theme colour options.
BLACK="\\033[00;30m"
RED="\\033[00;31m"
ORANGE="\\033[00;38;5;214m"
GREEN="\\033[00;32m"
YELLOW="\\033[00;33m"
BLUE="\\033[00;34m"
MAGENTA="\\033[00;35m"
CYAN="\\033[00;36m"
GRAY="\\033[00;40m"
WHITE="\\033[00;37m"

## Set theme colour.
COL="${GREEN}"
COL_L="${COL}"

BOLD="\\033[1m"
DIM="\\033[2m"
RESET="\\033[0m"

###############################################################################################################################################################
## Bios info
BIOS_DATE=$(cat /sys/devices/virtual/dmi/id/bios_date)
BIOS_VERSION=$(cat /sys/devices/virtual/dmi/id/bios_version)
BIOS_VENDOR=$(cat /sys/devices/virtual/dmi/id/bios_vendor)
S01="${COL}${BOLD}Bios:${RESET} ${BIOS_DATE}, version ${BIOS_VERSION} (${BIOS_VENDOR})"	## Bios date, version, vendor

###############################################################################################################################################################
## CPU info
CPU_MODEL=$(lscpu | grep "Model name" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_VENDOR=$(lscpu | grep "Vendor ID" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_ARCH=$(lscpu | grep "Architecture" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_MODE=$(lscpu | grep "CPU op-mode" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_CORES=$(lscpu | grep -m 1 "CPU(s)" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_SPEED=$(lscpu | grep "CPU MHz" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_MAX_SPEED=$(lscpu | grep "CPU max" | tr -s " " | cut -d ":" -f 2 | cut -c2-)
CPU_MIN_SPEED=$(lscpu | grep "CPU min" | tr -s " " | cut -d ":" -f 2 | cut -c2-)

S02="${COL}${BOLD}Processor:${RESET}"
S03="${COL}--Model:${RESET} ${CPU_MODEL}"		## CPU model
S04="${COL}--Vendor:${RESET} ${CPU_VENDOR}"		## CPU vendor
S05="${COL}--Architecture:${RESET} ${CPU_ARCH}"		## Architecture
S06="${COL}--Mode(s):${RESET} ${CPU_MODE}"		## CPU op-mode(s)
S07="${COL}--Cores:${RESET} ${CPU_CORES}"		## CPU(s)
S08="${COL}--Speed:${RESET} ${CPU_SPEED}MHz"		## CPU MHz
S09="${COL}--Max Speed:${RESET} ${CPU_MAX_SPEED}MHz"	## Max CPU MHz
S10="${COL}--Min Speed:${RESET} ${CPU_MIN_SPEED}MHz"	## Min CPU MHz

###############################################################################################################################################################
## OS kernel and distribution info
S11="${COL}${BOLD}Operating System:${RESET}"
S12="${COL}--OS:${RESET} $(uname -o)"								## OS
S13="${COL}--Architecture:${RESET} $(uname -m)"							## Architecture
S14="${COL}--Kernel:${RESET} $(uname -s)"							## Kernel
S15="${COL}${DIM}----Version:${RESET} $(uname -v)"						## Kernel version
S16="${COL}${DIM}----Release:${RESET} $(uname -r)"						## Kernel release
S17="${COL}--Distribution:${RESET} $(grep "^PRETTY_NAME=" /etc/os-release | cut -d "\"" -f 2)"	## Distro
S18="${COL}${DIM}----Version:${RESET} $(grep "^VERSION=" /etc/os-release | cut -d "\"" -f 2)"	## Distro version
S19="${COL}${DIM}----ID:${RESET} $(grep "^ID=" /etc/os-release | cut -d "=" -f 2)"		## Distro ID
S20="${COL}${DIM}----Codename:${RESET} $(lsb_release -c | cut -f2)"				## Distro codename

###############################################################################################################################################################
## Output
echo -e "
${COL_L}${BOLD}               ____	    ${S01}
${COL_L}${BOLD}              /   /    /\    ${S02}
${COL_L}${BOLD}             /   /    /  \    ${S03}
${COL_L}${BOLD}            /   /    /    \    ${S04}
${COL_L}${BOLD}           /   /    /      \    ${S05}
${COL_L}${BOLD}          /   /    /   /\   \    ${S06}
${COL_L}${BOLD}         /   /    /   /  \   \    ${S07}
${COL_L}${BOLD}        /   /    /    \   \   \    ${S08}
${COL_L}${BOLD}       /   /    /      \   \   \    ${S09}
${COL_L}${BOLD}      /   /    /   /\   \   \   \    ${S10}
${COL_L}${BOLD}     /   /    /   /  \   \   \   \    ${S11}
${COL_L}${BOLD}    /   /    /   /    \   \   \   \    ${S12}
${COL_L}${BOLD}   /   /____/   /______\   \   \   \    ${S13}
${COL_L}${BOLD}  /                         \   \   \    ${S14}
${COL_L}${BOLD} /________________________   \   \   \    ${S15}
${COL_L}${BOLD}                          \   \   \  /    ${S16}
${COL_L}${BOLD}   ________________________\   \   \/    ${S17}
${COL_L}${BOLD}   \                            \       ${S18}
${COL_L}${BOLD}    \____________________________\     ${S19}
${COL_L}${BOLD}				      ${S20}

"
