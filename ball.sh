#!/bin/bash

##Colours
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
BOLD="\033[01;37m"
RESET="\033[0m"

#Exit codes
SUCCESS=0
#TOO_MANY_ARGS=1	#incorrest usage
BAD_LIST_FILE=2	#specified or default file list not readable
#NO_SERVICE=3    #neither rsync nor scp are installed
#NO_REM_DIR=4	#ssh command to create remote directory failed

TEMP_SUMMARY_FILE="$(dirname "$0")/summary"	#define the temp file location so that the script will work even if run from a directory without write access


REM_SYS_LIST=${1-"$(dirname $0)/ball.list"}	#First argument is the file name of the list of remote systems.
						#If argument not provided, set default (ball.list in same dir as script).
						#Syntax: parameter=${parameter-default}


#Validate the list of remote systems.
echo
echo "Remote system list is \"$REM_SYS_LIST\""
if [ ! -f "$REM_SYS_LIST" ] || [ ! -r "$REM_SYS_LIST" ]; then	#If ball.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "${RED}Remote system list \"$REM_SYS_LIST\" not found, invalid file type or no read access.${RESET}"
	exit $BAD_LIST_FILE
fi
echo -e "${GREEN}Remote system list \"$REM_SYS_LIST\" validated.${RESET}"


#Loop through the remote system list.
echo
echo "-----------------------------------------------------------------------"
while read -r REM_SYS <&2; do	##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
				##<&2 needed as descriptor for nested while read loops (while read loop within called script)

	if ! ssh $REM_SYS "~/bin/bu.sh"; then
		echo "$REM_SYS\t ${RED}Failure.${RESET}" >> $TEMP_SUMMARY_FILE
		continue
	else
		echo "$REM_SYS\t ${GREEN}Success.${RESET}" >> $TEMP_SUMMARY_FILE
	fi
	echo "-----------------------------------------------------------------------"

done 2< "$REM_SYS_LIST"		##File read by the while loop which includes a list of files to be backed up.

echo
echo
echo -e "${BOLD}╔════════Summary:════════╗${RESET}"
while read -r RESULT ; do
	echo -e ${BOLD}║${RESET}${RESULT}${BOLD}║${RESET}
done < "$TEMP_SUMMARY_FILE"
echo -e "${BOLD}╚════════════════════════╝${RESET}"
echo

rm $TEMP_SUMMARY_FILE
exit $SUCCESS
