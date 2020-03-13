#!/bin/bash

##This script will take as an input either a specific file or a list of multiple files.
##These files will be backed up to the specified server.

##########Configurable settings
BU_USER="b4t"
BU_SERVER_LOCAL="seymour"
BU_SERVER_REMOTE="clews.pro"
BU_REMOTE_DIR="/home/$BU_USER/file_cache/$HOSTNAME"

##########Colours
RED="\033[02;31m"
ORANGE="\033[02;33m"
GREEN="\033[02;32m"
BLUE="\033[01;34m"
RESET="\033[0m"

##########Exit codes
SUCCESS=0	## Noice
BAD_USAGE=1	## incorrest usage
BAD_ARGUMENT=2	## specified or default file list not readable
BAD_LIST_FILE=3	## list file not identified as ascii text file
NO_SERVICE=4	## neither rsync nor scp are installed
NO_REM_DIR=5	## ssh command to create remote directory failed

##########Usage
USAGE="
Usage: $(basename "$0") [option] [file/list]
Where [file/list] is either:
	file	-	a specific file/directory to be backed up (requires option \"-f\").
	list	-	a text list of files/directories to be backed up.
Valid options:
	-f	-	Argument is a specific file/directory to be backed up.
	-d	-	Argument is a specific file/directory to be backed up.
	-l	-	Argument is a text file containing a list of file/directories to be backed up.
	-v	- 	Verbose - print additional info to stdout.
	-h	-	Print this usage and exit.
	none	-	No option entered - Default assumes \"-l\".
"

DEST="/dev/null"	## Default destination for command output.  I.e. don't display on screen.  -v (verbose) option changes this.

##########Interpret options
while getopts 'fdlvh' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		f)	ARGUMENT_TYPE="FILE" ;;		## -f identifies the provided argument as a directory/file to be backed up.
		d)	ARGUMENT_TYPE="FILE" ;;		## -d identifies the provided argument as a directory/file to be backed up.
		l)	ARGUMENT_TYPE="LIST" ;;		## -l identifies the argument as a list of files to be backed up.
		v)	DEST="/dev/stdout" ;;		## -v activates verbose mode by sending output to /dev/stdout (instead of /dev/null).
		h)	echo -e "$USAGE"		## -h option just prints the usage then quits.
			exit ${SUCCESS}			## Exit successfully.
			;;
		?)
			echo -e "Invalid option/s."
			echo -e "$USAGE"		## Invalid option, show usage.
			exit ${BAD_USAGE}		## Exit.
			;;
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

##########Check correct usage
if [ $# -gt 1 ]; then			## Check if more than one argument was entered.
	echo -e "Too many arguments."	## If so, show usage and exit.
	echo -e "${USAGE}"
	exit ${BAD_USAGE}
fi

if [ "${ARGUMENT_TYPE}" == "FILE" ] && [ $# -lt 1 ]; then	## Check if expected argument is a file but no argument entered.
	echo -e "Missing argument."				## If true, show usage and exit.
	echo -e "${USAGE}"					## (Note, no argument acceptable for -l option as default list file will be assumed)
	exit ${BAD_USAGE}
fi

##########Validate argument
ARGUMENT=${1-"$(dirname "$0")/bu.list"}	## First argument is the file name of the list of files to be backed up or a specific file to be backed up..
					## If argument not provided, set default (bu.list in same dir as script).
					## Syntax: parameter=${parameter-default}

if [ ! -e "${ARGUMENT}" ]; then		## Check the argument exists
	echo -e	"File \"${ARGUMENT}\" does not exist."
	echo -e "${USAGE}"
	exit ${BAD_ARGUMENT};
fi

##########Verify if rsync is installed.  If not, verify scp is installed.
echo -e "\nChecking for rsync (preferred) or scp:" > ${DEST}
if ! command -v rsync >> /dev/null; then		## If rsync not installed (send to /dev/null to suppress stdout)
	echo -e "${ORANGE}Warning: rsync not installed.${RESET}  Defaulting to scp for backup operations" > ${DEST}
	if ! command -v scp >> /dev/null; then		## if scp not installed (send to /dev/null to suppress stdout)
		echo -e "${RED}Error: neither rsync nor scp is installed.${RESET}  Quitting."
		exit ${NO_SERVICE}
	fi
	RSYNC_INSTALLED="FALSE"	## Flag false so scp is used for copy operations
else
	echo -e "${GREEN}Confirmation:${RESET} rsync installed." > ${DEST}
	RSYNC_INSTALLED="TRUE"	## Flag true so rsync is used for copy operations
fi

##########Determine server hostname (i.e. use local network or remote network).
echo -e "\nChecking for local backup server availability." > ${DEST}
if timeout 6 ssh -o "BatchMode=yes" "${BU_SERVER_LOCAL}" "exit" > ${DEST} 2>&1; then	## If an ssh connection to the local server is successful...
	BU_SERVER="${BU_SERVER_LOCAL}"							## Use the local server.
	echo "Using local server (${BU_SERVER})." > ${DEST}
else
	BU_SERVER="${BU_SERVER_REMOTE}"							## Otherwise, use the remote server.
	echo "Using remote server (${BU_SERVER})." > ${DEST}
fi

##########Validate the backup folder or create if absent.
echo -e "\nChecking for remote backup directory \"${BU_REMOTE_DIR}\" on remote backup server \"${BU_SERVER}\" (will be created if absent)." > ${DEST}
if ! ssh -t ${BU_USER}@${BU_SERVER} "mkdir -p ${BU_REMOTE_DIR}" > ${DEST} 2>&1; then	## Connects to the remote server and creates the backup dir.
	echo -e "${RED}Failed to create remote directory${RESET}"			## If this fails, print error and exit.
	exit ${NO_REM_DIR}
fi
echo -e "${GREEN}Remote backup directory \"${BU_REMOTE_DIR}\" validated.${RESET}" > ${DEST}

##########Create the temp list file.
TEMP_BU_FILE_LIST="/tmp/temp_bu_file_list"				## Define the temporary file which will contain a list of file/s to be backed up..
if [ -e "${TEMP_BU_FILE_LIST}" ]; then rm "${TEMP_BU_FILE_LIST}"; fi	## If it exists, delete the temp file (in case script failed previously before deleting).

##########Fill the temp list file (i.e. validate, strip comments).
if [ "${ARGUMENT_TYPE}" == "FILE" ]; then						## If provided argument is a specific file to be backed up (option -f)
	ARGUMENT="$(readlink -f "${ARGUMENT}")"						## Convert to full path (readlink -f will convert from relative path.)
	echo -e "\nBackup the following file: ${ARGUMENT}" > ${DEST}			## Print the file to be backed up.
	echo "${ARGUMENT}" > "${TEMP_BU_FILE_LIST}"					## Create the list of files to be backed up - in this case a list of one.
											## Use find to capture the absolute directory location of the file.
else											## Else if argument is not a specific file, assume it is a list of files.
	if	command -v file >> /dev/null && 					## If "file" is installed and...
		! file "${ARGUMENT}" | grep "ASCII text" >> /dev/null; then		## list file is not ascii text (as expected).
			echo -e "Bad backup list file (expecting ascii text file)."	## Then print usage and exit.
			echo -e "${USAGE}"
			exit ${BAD_LIST_FILE}
	else
		echo -e "\nBackup list is \"$ARGUMENT\". Checking files..." > ${DEST}	## Else the argument is assumed a list of files (option -l or no option).
		while read -r LINE ; do							## Iterate for every line in the backup file list.
			STRIPPED_LINE=$(echo "${LINE}" | tr -s " " | tr -d "\t" | cut -d "#" -f 1)	## Strip the comments.
													## 1) Squash any repeated spaces into a single space.
														#(Can't delete in case filename has spaces)
													## 2) Delete any tabs.
													## 3) Delete content of the line from the first '#'.
			if [ "${STRIPPED_LINE}" ]; then 						## If there is anything left of the stripped line.
				if [ "$(echo "${STRIPPED_LINE}" | cut -b ${#STRIPPED_LINE})" == " " ]; then	## If there is a trailing space left at the end...
					STRIPPED_LINE="$(echo "${STRIPPED_LINE}" | cut --complement -b ${#STRIPPED_LINE})";	## Then delete the trailing space.
				fi
				FULL_PATH=${STRIPPED_LINE/#\~/$HOME}				## Expanded variable will be treated as a literal string.
				FULL_PATH=${FULL_PATH/\$HOME/$HOME}				## These two commands evaluate first "~" and then "$HOME"
												## then substitute either for the actual variable $HOME
												## Syntax: ${variable/string_match/replacement}
				if [ -e "${FULL_PATH}" ]; then					## If the stripped and expanded line exists as a file
					echo -e "Adding: ${GREEN}${FULL_PATH}${RESET}" > ${DEST}		## Say so and then
					echo "${FULL_PATH}" >> "${TEMP_BU_FILE_LIST}"			## copy the stripped/expanded line to the temp file.
				else
					echo -e "Failed: ${RED}${FULL_PATH}${RESET} does not exist and will be skipped"	## Else skip the line.
				fi
			fi
		done < "${ARGUMENT}"
		if [ ! -e "${TEMP_BU_FILE_LIST}" ]; then							## If the temp list file was not created
			echo -e "${RED}The list file did not contain any valid files to back up.${RESET}"	## Then it didn't contain any valid files.
			echo -e "${USAGE}"									## So print usage and exit.
			exit ${BAD_LIST_FILE}
		fi
	fi
fi

##########Run the sync.
echo > ${DEST}
if [ "$RSYNC_INSTALLED" == "TRUE" ]; then	## Use rsync (preferred, dir structure will be retained within backup dir).
	echo -e "${BLUE}Using rsync to copy listed files to \"${RESET}${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/${BLUE}\"${RESET}"
	if ! rsync --recursive --relative --verbose --human-readable --progress --archive --files-from="${TEMP_BU_FILE_LIST}" / "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/" > ${DEST}; then
		echo -e "${RED}Failure.${RESET}"	## If rsync failed
		#continue	## Proceed to the next file in the list.
	else	
		echo -e "${GREEN}Success.${RESET}"			
	fi
else						## Use scp (dir structure will not be retained)
	echo -e "${BLUE}Using scp to copy listed files to \"${RESET}${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/${BLUE}\"${RESET}"
	while read -r BU_FILE; do		## Must loop to run scp for every entry in list file.
		if ! scp -r -B "${BU_FILE}" "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/" > ${DEST}; then
			echo -e "${RED}Failure:${RESET} ${BU_FILE}"		## If scp failed
			continue					## Proceed to the next file in the list.
		else
			echo -e "${GREEN}Success.${RESET} ${BU_FILE}"			
		fi
	done < "${TEMP_BU_FILE_LIST}"
	fi

##########Delete the temp file.
rm "${TEMP_BU_FILE_LIST}"

##########All done.
echo -e "\nScript complete.\n" > ${DEST}
exit ${SUCCESS}
