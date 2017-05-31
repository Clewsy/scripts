#!/data/data/com.termux/files/usr/bin/bash

##Colours
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

echo "---Entering \"Download\" directory"
cd /storage/emulated/0/Download/
echo "current directory= $(pwd)"

if [ -z $(which termux-clipboard-get) ]; then
	echo
	echo "---termux-api not installed. Installing now:"
	apt install termux-api
fi

echo
echo "---Fetching url from clipboard: (if this hangs, ctrl-c to exit then install termux-api from f-droid)"
url=$(termux-clipboard-get)

if [ -z $url ]; then
	echo "---Nothing in clipboard, quitting."
	exit -1
fi

echo "----------"

while true
do
	echo
	echo "url= $url"
	echo "---Executing youtube-dl and selecting best video quality"
	youtube-dl -c -f best $url
	if [ $? = '0' ]; then
		echo
		echo -e "${GREEN}---all done!${RESET}"
		termux-notification -i "ytdl" -c "Download complete" -t "$(basename $0)"
		termux-toast "Download complete ($(basename $0))"
		exit 129
	else
		echo
		echo -e ${RED}---download failed or incomplete.${RESET}
		read -n1 -p "---press any key to try again."
		echo
	fi
done

