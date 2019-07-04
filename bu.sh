#!/bin/bash

##This script will take as an input either a specific file or a list of multiple files.
##These files will be backed up to the specified server.

##Colours
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
RESET="\033[0m"

#Exit codes
SUCCESS=0	#Noice
BAD_USAGE=1	#incorrest usage
BAD_ARGUMENT=2	#specified or default file list not readable
BAD_LIST_FILE=3	#list file not identified as ascii text file
NO_SERVICE=4	#neither rsync nor scp are installed
NO_REM_DIR=5	#ssh command to create remote directory failed

#Configurable settings
BU_USER="b4t"
BU_SERVER_LOCAL="seymour.local"
BU_SERVER_REMOTE="b4t.site"
BU_REMOTE_DIR="/home/$BU_USER/file_cache/$HOSTNAME"

USAGE="
Usage: $(basename $0) [option] [file/list]
Where [file/list] is either:
	file	-	a specific file/directory to be backed up (requires option \"-f\").
	list	-	a text list of files/directories to be backed up.
Valid options:
	-f	-	Argument is a specific file/directory to be backed up.
	-d	-	Argument is a specific file/directory to be backed up.
	-l	-	Argument is a text file containing a list of file/directories to be backed up.
	-h	-	Print this usage and exit.
	none	-	No option entered - Default assumes \"-l\".
"

while getopts 'fdlh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	OPTIONS="TRUE"				## Used to determine if a valid or invalid option was entered.
	case "$OPTION" in
		f)	ARGUMENT_TYPE="FILE" ;;	## -f identifies the provided argument as a directory/file to be backed up.
		d)	ARGUMENT_TYPE="FILE" ;;	## -d identifies the provided argument as a directory/file to be backed up.
		l)	ARGUMENT_TYPE="LIST" ;;	## -l identifies the argument as a list of files to be backed up.
		h)	echo -e "$USAGE"	## -l option just prints the usage then quits.
			exit 0			## Exit successfully.
			;;
		?)
			echo -e "Invalid option/s."
			echo -e "$USAGE"	## Invalid option, show usage.
			exit ${BAD_USAGE}	## Exit.
			;;
	esac
done
shift $(($OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

if [ -z "$OPTIONS" ]; then ARGUMENT_TYPE="LIST"; fi	## Check if no options were entered.  If so, set the ALL flag.

if [ $# -gt 1 ]; then			## Check if more than one argument was entered.
	echo -e "Too many arguments."	## If so, show usage and exit.
	echo -e "${USAGE}"
	exit ${BAD_USAGE}
fi

if [ ${ARGUMENT_TYPE} == "FILE" ] && [ $# -lt 1 ]; then	##Check if expected argument is a file but no argument entered.
	echo -e "Missing argument."			##If true, show usage and exit.
	echo -e "${USAGE}"				##(Note, no argument acceptable for -l option as default list file will be assumed)
	exit ${BAD_USAGE}
fi

ARGUMENT=${1-"$(dirname "$0")/bu.list"}	#First argument is the file name of the list of files to be backed up.
					#If argument not provided, set default (bu.list in same dir as script).
					#Syntax: parameter=${parameter-default}

if [ ! -e "${ARGUMENT}" ]; then		#Check the argument exists
	echo -e	"File \"${ARGUMENT}\" does not exist."
	echo -e "${USAGE}"
	exit ${BAD_ARGUMENT};
fi

TEMP_BU_FILE_LIST="$(dirname $0)/temp_bu_file_list"	#Define the temporary file which will contain a list of file/s to be backed up..

if [ "${ARGUMENT_TYPE}" == "FILE" ]; then						#If provided argument is a specific file to be backed up (option -f)
	echo -e "Backup the following file: ${ARGUMENT}"				#Print the file to be backed up.
	echo "$(find $(pwd) -name $(basename ${ARGUMENT}))" > ${TEMP_BU_FILE_LIST}	#Create the list of files to be backed up - in this case a list of one.
											#Use find to capture the absolute directory location of the file.
else
	if ! $(file "${ARGUMENT}" | grep "ASCII text" >> /dev/null); then	#Check that the list file is ascii text as expected.
		echo -e "Bad backup list file (expecting ascii text file)."	#If not, print usage and exit.
		echo -e "${USAGE}"
		exit ${BAD_LIST_FILE}
	else
		echo "Backup file list is \"$ARGUMENT\""			#Else the argument is assumed a list of files (option -l or no option).
		while read -r LINE ; do						#Iterate for every line in the backup file list.
			STRIPPED_LINE="$(echo ${LINE} | cut -d "#" -f 1)"	#Strip the content of the line after (and including) the first '#'.
			if [ -e "${STRIPPED_LINE}" ]; then				#If there is anything left in the string (i.e. if entire row is NOT a comment)
				echo ${STRIPPED_LINE} >> "${TEMP_BU_FILE_LIST}"	#Then copy the stripped line to the temp file.
			fi
		done < "${ARGUMENT}"
		if [ ! -e ${TEMP_BU_FILE_LIST} ]; then						#If the temp list file was not created
			echo -e "The list file did not contain any valid files to back up."	#Then id didn't contain any valid files.
			echo -e "${USAGE}"							#So print usage and exit.
			exit ${BAD_LIST_FILE}
		fi
	fi
fi

#Verify if rsync is installed.  If not, verify scp is installed.
echo -e "Checking for rsync (preferred) or scp:"
if ! command -v rsync >> /dev/null; then		#If rsync not installed (send to /dev/null to suppress stdout)
	echo
	echo -e "${ORANGE}Warning: rsync not installed.${RESET}  Defaulting to scp for backup operations"
	if ! command -v scp >> /dev/null; then	#if scp not installed (send to /dev/null to suppress stdout)
		echo -e "${RED}Error: scp is also not installed.${RESET}  Quitting."
		exit ${NO_SERVICE}
	fi
	RSYNC_INSTALLED="FALSE"	#Flag false so scp is used for copy operations
else
	echo -e "${GREEN}Confirmation:${RESET} rsync installed."
	RSYNC_INSTALLED="TRUE"	#Flag true so rsync is used for copy operations
fi

#Determine server hostname (i.e. use local network or remote network).
echo
echo "Checking for local backup server availability."
if ping -c 1 -W 1 "${BU_SERVER_LOCAL}" >> /dev/null; then	#If a ping to the local server is successful...
	BU_SERVER="${BU_SERVER_LOCAL}"			#Use the local server.
	echo "Using local server (${BU_SERVER})."
else
	BU_SERVER="${BU_SERVER_REMOTE}"			#Otherwise, use the remote server.
	echo "Using remote server (${BU_SERVER})."
fi

#Validate the backup folder or create if absent.
echo
echo "Checking for remote backup directory \"${BU_REMOTE_DIR}\" on remote backup server \"${BU_SERVER}\" (will be created if absent)."
if ! ssh ${BU_USER}@${BU_SERVER} "mkdir -p ${BU_REMOTE_DIR}"	#Connects to the remote server and creates the directory to which bu files will be copied.
then			#Checks the exit code from the SSH command.  If not zero, then it failed.
	echo -e "${RED}Failed to create remote directory${RESET}"
	exit ${NO_REM_DIR}
fi
echo -e "${GREEN}Remote backup directory \"${BU_REMOTE_DIR}\" validated.${RESET}"


#Loop through the file list, validate file names and run backup command
#(Actually using the temp file list which is the same as the file list but with comments stripped).
echo
while read -r BU_FILE ; do		##Loop to repeat commands for each file name entry in the backup file list ($BU_FILE_LIST)
        echo "--------"
	#Expand the filename
	echo "File/Directory name as listed in \"${BU_FILE_LIST}\": $BU_FILE"	#Filename as read from backup file list
	FULL_PATH="${BU_FILE/#\~/$HOME}"		#Expanded variable will be treated as a literal string.
	FULL_PATH="${FULL_PATH/\$HOME/$HOME}"		#These two commands evaluate first "~" and then "$HOME"
							#then substitute either for the actual variable $HOME
							#Syntax: ${variable/string_match/replacement}
	echo "Expanded filename: \"${FULL_PATH}\""
	if [ ! -e "${FULL_PATH}" ]; then	#Check file exists, if file doesn't exist
		echo -e "${RED}File/Directory \"${FULL_PATH}\" does not exist.  Skipping...${RESET}"
		continue			#Exit the loop and restart for the next file in the list.
	fi
	echo "File/Directory \"${FULL_PATH}\" exists."

	echo -e "${BLUE}Backing up \"${FULL_PATH}\" to \"${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/${RESET}"	#Run copy command (rsync or scp)
	if [ "$RSYNC_INSTALLED" == "TRUE" ]; then	#Use rsync (preferred, dir structure will be retained within backup dir)
		if ! rsync -r -R -v --progress "${FULL_PATH}" "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/"; then	#Execute rsync, check for exit error
			echo -e "${RED}Failed to copy ${FULL_PATH} to remote directory.${RESET}"
			continue	#Proceed to the next file in the list.
		fi
	else						#Use scp (dir structure will not be retained)
		if ! scp -r -B "${FULL_PATH}" "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/"; then			#Execute scp, check for exit error
			echo -e "${RED}Failed to copy ${FULL_PATH} to remote directory.${RESET}"
			continue	#Proceed to the next file in the list.
		fi
	fi
	echo -e "${GREEN}Success.${RESET}"
done < "$TEMP_BU_FILE_LIST"	#File read by the while loop which includes a list of files to be backed up.

rm $TEMP_BU_FILE_LIST		#Delete the temporary file list (file list with comments stripped).

echo
echo "Script complete"
echo
exit ${SUCCESS}
