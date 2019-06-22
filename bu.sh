#!/bin/bash

usage="Usage: $(basename "$0") <backup file list>"

##Colours
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
RESET="\033[0m"

#Exit codes
TOO_MANY_ARGS=1	#incorrest usage
BAD_FILE_LIST=2	#specified or default file list not readable
NO_SERVICE=3    #neither rsync nor scp are installed
NO_REM_DIR=4	#ssh command to create remote directory failed

#Configurable settings
BU_USER="b4t"
BU_SERVER_LOCAL="seymour.local"
BU_SERVER_REMOTE="b4t.site"
BU_REMOTE_DIR="/home/$BU_USER/file_cache/$HOSTNAME"
BU_FILE_LIST=${1-"$(dirname "$0")/bu.list"}	#First argument is the file name of the list of files to be backed up.
						#If argument not provided, set default (bu.list in same dir as script).
						#Syntax: parameter=${parameter-default}

#Check valid usage.
if [ $# -gt 1 ]; then	#Check than no more than one argument is provided.
	echo -e "${RED}Too many arguments${RESET}"
	echo "$usage"
	exit $TOO_MANY_ARGS
fi

#Validate the backup file list.
echo
echo "Backup file list is \"$BU_FILE_LIST\""
if [ ! -f "$BU_FILE_LIST" ] || [ ! -r "$BU_FILE_LIST" ]; then	#If bu.list is not (!) a normal file (-f) or (||) in is not (!) readable (-r)
	echo -e "${RED}Backup file list \"$BU_FILE_LIST\" not found, invalid file type or no read access.${RESET}"
	exit $BAD_FILE_LIST
fi
echo -e "${GREEN}Backup file list \"$BU_FILE_LIST\" validated.${RESET}"

#Create a working backup file list from the original file list but with #comments stripped.
TEMP_BU_FILE_LIST="$(dirname $0)/temp_bu_file_list"		#Create the temporary file.
while read -r LINE ; do						#Iterate for every line in the backup file list.
	STRIPPED_LINE="$(echo ${LINE} | cut -d "#" -f 1)"	#Strip the content of the line after (and including) the first '#'.
	if [ $STRIPPED_LINE != "\n" ] ; then			#If all that is left is NOT just a "newline" (i.e. if entire row is NOT a comment)
	  	echo $STRIPPED_LINE >> "${TEMP_BU_FILE_LIST}"	#Then copy the stripped line to the temp file.
	fi
done < "${BU_FILE_LIST}"

#Verify if rsync is installed.  If not, verify scp is installed.
echo
echo -e "Checking for rsync (preferred) or scp:"
if ! command -v rsync >> /dev/null ; then		#If rsync not installed (send to /dev/null to suppress stdout)
	echo
	echo -e "${ORANGE}Warning: rsync not installed.${RESET}  Defaulting to scp for backup operations"
	if ! command -v scp >> /dev/null; then	#if scp not installed (send to /dev/null to suppress stdout)
		echo -e "${RED}Error: scp is also not installed.${RESET}  Quitting."
		exit $NO_SERVICE
	fi
	RSYNC_INSTALLED="FALSE"	#Flag false so scp is used for copy operations
else
	echo -e "${GREEN}Confirmation:${RESET} rsync installed."
	RSYNC_INSTALLED="TRUE"	#Flag true so rsync is used for copy operations
fi

#Determine server hostname (i.e. use local network or remote network).
echo
echo "Checking for local backup server availability."
if ping -c 1 -W 1 "$BU_SERVER_LOCAL" >> /dev/null; then	#If a ping to the local server is successful...
	BU_SERVER="$BU_SERVER_LOCAL"			#Use the local server.
	echo "Using local server (${BU_SERVER})."
else
	BU_SERVER="$BU_SERVER_REMOTE"			#Otherwise, use the remote server.
	echo "Using remote server (${BU_SERVER})."
fi

#Validate the backup folder or create if absent.
echo
echo "Checking for remote backup directory \"$BU_REMOTE_DIR\" on remote backup server \"$BU_SERVER\" (will be created if absent)."
if ! ssh $BU_USER@$BU_SERVER "mkdir -p $BU_REMOTE_DIR"	#Connects to the remote server and creates the directory to which bu files will be copied.
then			#Checks the exit code from the SSH command.  If not zero, then it failed.
	echo -e "${RED}Failed to create remote directory${RESET}"
	exit $NO_REM_DIR
fi
echo -e "${GREEN}Remote backup directory \"${BU_REMOTE_DIR}\" validated.${RESET}"


#Loop through the file list, validate file names and run backup command
#(Actually using the temp file list which is the same as the file list but with comments stripped).
echo
while read -r BU_FILE ; do		##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
        echo "--------"
	#Expand the filename
	echo "File/Directory name as listed in \"${BU_FILE_LIST}\": $BU_FILE"		#Filename as read from backup file list
	FULL_PATH="${BU_FILE/#\~/$HOME}"				#Expanded variable will be treated as a literal string.
	FULL_PATH="${FULL_PATH/\$HOME/$HOME}"				#These two commands evaluate first "~" and then "$HOME"
									#then substitute either for the actual variable $HOME
									#Syntax: ${variable/string_match/replacement}
	echo "Expanded filename: \"${FULL_PATH}\""
	#Check file exists
	if [ ! -e "${FULL_PATH}" ]; then	#If file doesn't exist
		echo -e "${RED}File/Directory \"${FULL_PATH}\" does not exist.  Skipping...${RESET}"
		continue		#Exit the loop and restart for the next file in the list.
	fi
	echo "File/Directory \"${FULL_PATH}\" exists."

	#Run copy command (rsync or scp)
	echo -e "${BLUE}Backing up \"${FULL_PATH}\" to \"${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/${RESET}"
	if [ "$RSYNC_INSTALLED" == "TRUE" ]; then	#Use rsync (preferred, dir structure will be retained within backup dir)
		if ! rsync -r -R -v --progress "${FULL_PATH}" "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/"; then	#Execute rsync, check for exit error
			echo -e "${RED}Failed to copy ${FULL_PATH} to remote directory.${RESET}"
			continue
		fi
	else						#Use scp (dir structure will not be retained)
		if ! scp -r -B "${FULL_PATH}" "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/"; then	#Execute scp, check for exit error
			echo -e "${RED}Failed to copy ${FULL_PATH} to remote directory.${RESET}"
			continue
		fi
	fi
	echo -e "${GREEN}Success.${RESET}"

done < "$TEMP_BU_FILE_LIST"	#File read by the while loop which includes a list of files to be backed up.

rm $TEMP_BU_FILE_LIST		#Delete the temporary file list (file list with comments stripped).

echo
echo "Backup complete"
echo
exit 0
