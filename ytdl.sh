#!/data/data/com.termux/files/usr/bin/bash
#: Title:	: ytdl
#: Author	: clewsy (clewsy.pro)
#: Description	: Quickly download an online video to the local device.  Intended for use with Termux as a widget shortcut.
#:		: The contents of the clipboard is assumed to be a video url which this script will download using youtube-dl.
#: Options	: none

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

printf "%b" "---Entering \"Download\" directory\n"
if ! cd ${DEFAULT_DOWNLOAD_DIR}; then	#change dir or quit on failure.
	printf "%b" "\n${RED}---error accessing specified download directory.${RESET}  Has \"termux-setup-storage\" been run?\n"
	exit ${NO_DL_DIR}; fi

printf "%b" "Current directory= ${PWD}\n"

if ! command -v termux-clipboard-get; then	#if the termux-clipboard-get command is absent then termux-api has not been installed
	printf "%b" "\n---termux-api not installed. Installing now...\n"
	if ! apt install termux-api; then
		printf "%b" "\n---${RED}Unable to install termux-api.${RESET}  Quitting.\n"
		exit ${NO_TERMUXAPI}; fi
fi

printf "%b" "\n---Fetching url from clipboard...\n"
printf "%b" "(if this hangs, ctrl-c to exit then install termux-api from f-droid)\n"
printf "%b" "(alternatively, try updating youtube-dl with \"sudo pip install --upgrade youtube-dl\")\n"
URL=$(termux-clipboard-get)

if [ -z "${URL}" ]; then
	printf "%b" "---${RED}Nothing in clipboard.${RESET}  Quitting.\n"
	exit ${NO_URL}; fi

printf "%b" "---------------\n"

while true; do	#loop until download is successful
	printf "%b" "\nurl= ${URL}\n"
	printf "%b" "---Executing youtube-dl and selecting best video quality...\n"
	if youtube-dl -c --mark-watched -f best "${URL}"; then		#execute youtube-dl and check for success on exit.
		printf "%b" "\n${GREEN}---all done!${RESET}\n"
		termux-notification -i "ytdl" -c "Download complete" -t "${0##*/}"
		termux-toast "Download complete (${0##*/})"
		exit ${SUCCESS}
	else
		printf "%b" "\n${RED}---download failed or incomplete.${RESET}\n"
		read -r -n1 -p "---press any key to try again."
	fi
done
