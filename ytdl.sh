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

echo "---Entering \"Download\" directory"
if ! cd ${DEFAULT_DOWNLOAD_DIR}; then	#change dir or quit on failure.
	echo
	echo -e "${RED}---error accessing specified download directory.${RESET}  has \"termux-setup-storage\" been run?"
	exit -1
fi

echo "current directory= $(pwd)"

if [ -z "$(which termux-clipboard-get)" ]; then	#if the termux-clipboard-get command is absent then termux-api has not been installed
	echo
	echo "---termux-api not installed. Installing now:"
	apt install termux-api
fi

echo
echo "---Fetching url from clipboard:"
echo "	(if this hangs, ctrl-c to exit then install termux-api from f-droid)"
echo "	(alternatively, try updating youtube-dl with \"sudo pip install --upgrade youtube-dl\")"
url=$(termux-clipboard-get)

if [ -z "$url" ]; then
	echo "---Nothing in clipboard, quitting."
	exit -1
fi

echo "----------"

while true	#loop until download is successful
do
	echo
	echo "url= $url"
	echo "---Executing youtube-dl and selecting best video quality"
	if youtube-dl -c --mark-watched -f best "$url"; then	#execute youtube-dl and check for success on exit.
		echo
		echo -e "${GREEN}---all done!${RESET}"
		termux-notification -i "ytdl" -c "Download complete" -t "$(basename "$0")"
		termux-toast "Download complete ($(basename "$0"))"
		exit 129
	else
		echo
		echo -e "${RED}---download failed or incomplete.${RESET}"
		read -r -n1 -p "---press any key to try again."
		echo
	fi
done

