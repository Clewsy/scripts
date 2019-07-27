#!/data/data/com.termux/files/usr/bin/bash

#This script written to quickly begin downloading a youtube video to the local device.
#Written for use with termux, reccomended to be run from the ~/.shortcuts directory
#to enable use via the termux widget (shortcut from the homescreen).
#Whatever url is currently in the device's clipboard is passed to the script and the
#download begins immediately.
#
#Requirements:
#termux
#termux-api (installed from f-droid and also within termux with command "apt install termux-api")
#python (required for installation of youtube-dl via pip.  install with command "apt install python")
#youtube-dl (installed from within termux with command "pip install youtube-dl")


##Colours
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

##Defaults
DEFAULT_DOWNLOAD_DIR=/storage/emulated/0/Download/

##Exit Codes
SUCCESS=0
NO_DL_DIR=1
NO_TERMUXAPI=2
NO_URL=3

echo "---Entering \"Download\" directory"
if ! cd ${DEFAULT_DOWNLOAD_DIR}; then	#change dir or quit on failure.
	echo
	echo -e "${RED}---error accessing specified download directory.${RESET}  Has \"termux-setup-storage\" been run?"
	exit $NO_DL_DIR
fi

echo "current directory= $(pwd)"

if ! command -v termux-clipboard-get; then	#if the termux-clipboard-get command is absent then termux-api has not been installed
	echo
	echo "---termux-api not installed. Installing now:"
	if ! apt install termux-api; then
		echo
		echo -e "---${RED}Unable to install termux-api.${RESET}  Quitting."
		exit $NO_TERMUXAPI
	fi
fi

echo
echo "---Fetching url from clipboard:"
echo "(if this hangs, ctrl-c to exit then install termux-api from f-droid)"
echo "(alternatively, try updating youtube-dl with \"sudo pip install --upgrade youtube-dl\")"
URL=$(termux-clipboard-get)

if [ -z "${URL}" ]; then
	echo "---${RED}Nothing in clipboard.${RESET}  Quitting."
	exit $NO_URL
fi

echo "----------"

while true	#loop until download is successful
do
	echo
	echo "url= ${URL}"
	echo "---Executing youtube-dl and selecting best video quality"
	if youtube-dl -c --mark-watched -f best "${URL}"; then		#execute youtube-dl and check for success on exit.
		echo
		echo -e "${GREEN}---all done!${RESET}"
		termux-notification -i "ytdl" -c "Download complete" -t "$(basename "$0")"
		termux-toast "Download complete ($(basename "$0"))"
		exit $SUCCESS
	else
		echo
		echo -e "${RED}---download failed or incomplete.${RESET}"
		read -r -n1 -p "---press any key to try again."
		echo
	fi
done
