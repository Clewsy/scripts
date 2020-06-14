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
GREEN="\033[02;32m"
BLUE="\033[01;34m"
RESET="\033[0m"

##########Define log file and ensure directory exists.
BU_LOG_FILE="${HOME}/.log/bu.log"
if [ ! -d "$(dirname "${BU_LOG_FILE}")" ]; then mkdir --parents "$(dirname "${BU_LOG_FILE}")"; fi

##########Exit codes
SUCCESS=0		## Noice.
BAD_OPTION=1		## Incorrect usage.
TOO_MANY_ARGS=2		## More than one argument was provided.
MISSING_ARG=3		## Option -f or -d provided but argument was not provided.
BAD_ARG=4		## Specified or default file list not readable.
NO_RSYNC=5		## rsync not installed.
NO_REM_DIR=6		## ssh command to create remote directory failed.
BAD_LIST_FILE=7		## List file not identified as ascii text file.
NO_VALID_FILES=8	## Parsing list file  found no valid files to back up.
RSYNC_FAILED=9		## rsync command was reached but failed.

##########Function to print current date and time.  Used for logging.
TIMESTAMP () { echo -ne "$(date +%Y-%m-%d\ %T)"; }

##########Function for exit conditions.  Log error or success and exit.
QUIT ()
{
	if [ "${1}" -gt 0 ]; then	echo -e "$(TIMESTAMP) - Script failed with error code ${1}." >> "${BU_LOG_FILE}"
	else				echo -e "$(TIMESTAMP) - Script completed successfully." >> "${BU_LOG_FILE}"; fi
	exit "${1}"
}

##########Usage
USAGE="
Usage: $(basename "$0") [option] [file/list]
Where [file/list] is either:
	file	-	a specific file/directory to be backed up (requires option \"-f\" or \"-d\").
	list	-	a text list of files/directories to be backed up.
Valid options:
	-f	-	Argument is a specific file to be backed up.
	-d	-	Argument is a specific directory to be backed up.
	-l	-	Argument is a text file containing a list of file/directories to be backed up.
	-q	-	Quiet - suppress most output.
	-v	- 	Verbose - print additional info to stdout.
	-h	-	Print this usage and exit.
	none	-	No option entered - Default assumes \"-l\".
"

DEST="/dev/null"	## Default destination for command output.  I.e. don't display on screen.  -v (verbose) option changes this.

##########Interpret options
while getopts 'fdlqvh' OPTION; do		## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
		f)	ARGUMENT_TYPE="FILE" ;;	## -f identifies the provided argument as a directory/file to be backed up.
		d)	ARGUMENT_TYPE="FILE" ;;	## -d identifies the provided argument as a directory/file to be backed up.
		l)	ARGUMENT_TYPE="LIST" ;;	## -l identifies the argument as a list of files to be backed up.
		q)	QUIET_MODE="TRUE" ;;	## -q flag to suppress some output that would otherwise go to /dev/stdout.
		v)	DEST="/dev/stdout" ;;	## -v activates verbose mode by sending output to /dev/stdout (instead of /dev/null).
		h)	echo -e "$USAGE"	## -h option just prints the usage then quits.
			QUIT ${SUCCESS}	 ;;	## Exit successfully.
		?)	echo -e "${RED}Error:${RESET} Invalid option/s."
			echo -e "$USAGE"	## Invalid option, show usage.
			QUIT "${BAD_OPTION}" ;;	## Exit.
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.

##########Check correct usage
if [ $# -gt 1 ]; then						## Check if more than one argument was entered.
	echo -e "${RED}Error:${RESET} Too many arguments."	## If so, show usage and exit.
	echo -e "${USAGE}"
	QUIT "${TOO_MANY_ARGS}"
fi

if [ "${ARGUMENT_TYPE}" == "FILE" ] && [ $# -lt 1 ]; then	## Check if expected argument is a file but no argument entered.
	echo -e "${RED}Error:${RESET} Missing argument."	## If true, show usage and exit.
	echo -e "${USAGE}"					## (Note, no argument acceptable for -l option as default list file will be assumed).
	QUIT "${MISSING_ARG}"
fi

##########Validate argument
ARGUMENT=${1-"$(dirname "$0")/bu.list"}		## First argument is the file name of the list of files to be backed up or a specific file to be backed up..
						## If argument not provided, set default (bu.list in same dir as script).
						## Syntax: parameter=${parameter-default}
if [ ! -e "${ARGUMENT}" ]; then			## Check the argument exists
	echo -e	"${RED}Error:${RESET} File \"${ARGUMENT}\" does not exist."
	echo -e "${USAGE}"
	QUIT "${BAD_ARG}"
fi

##########Verify if rsync is installed.
echo -e "\nChecking for rsync:" > ${DEST}
if ! command -v rsync >> /dev/null; then	## If rsync not installed (send to /dev/null to suppress stdout)
	echo -e "${RED}Error:${RESET} rsync not installed."
	QUIT ${NO_RSYNC}
else
	echo -e "${GREEN}Confirmation:${RESET} rsync installed." > ${DEST}
fi

##########Determine server hostname (i.e. use local network or remote network).
echo -e "\nChecking for local backup server availability." > ${DEST}
if timeout 6 ssh -4 -o "BatchMode=yes" "${BU_SERVER_LOCAL}" "exit" > ${DEST} 2>&1; then	## If an ssh connection to the local server is successful...
	BU_SERVER="${BU_SERVER_LOCAL}"							## Use the local server.
	echo "Using local server (${BU_SERVER})." > ${DEST}
else
	BU_SERVER="${BU_SERVER_REMOTE}"							## Otherwise, use the remote server.
	echo "Using remote server (${BU_SERVER})." > ${DEST}
fi

##########Validate the backup folder or create if absent.
echo -e "\nChecking for remote backup directory \"${BU_REMOTE_DIR}\" on remote backup server \"${BU_SERVER}\" (will be created if absent)." > ${DEST}
if ! ssh -4 -t ${BU_USER}@${BU_SERVER} "mkdir -p ${BU_REMOTE_DIR}" > ${DEST} 2>&1; then	## Connects to the remote server and creates the backup dir.
	echo -e "${RED}Error:${RESET} Failed to create remote directory."			## If this fails, print error and exit.
	QUIT ${NO_REM_DIR}
fi
echo -e "${GREEN}Remote backup directory \"${BU_REMOTE_DIR}\" validated.${RESET}" > ${DEST}

##########Create the temp list file.
TEMP_BU_FILE_LIST="/tmp/temp_bu_file_list"				## Define the temporary file which will contain a list of file/s to be backed up..
if [ -e "${TEMP_BU_FILE_LIST}" ]; then rm "${TEMP_BU_FILE_LIST}"; fi	## If it exists, delete the temp file (in case script failed previously before deleting).

##########Fill the temp list file (i.e. validate, strip comments).
if [ "${ARGUMENT_TYPE}" == "FILE" ]; then				## If provided argument is a specific file to be backed up (option -f)
	ARGUMENT="$(readlink -f "${ARGUMENT}")"				## Convert to full path (readlink -f will convert from relative path.)
	echo -e "\nBackup the following file: ${ARGUMENT}" > ${DEST}	## Print the file to be backed up.
	echo "${ARGUMENT}" > "${TEMP_BU_FILE_LIST}"			## Create the list of files to be backed up - in this case a list of one.
									## Use find to capture the absolute directory location of the file.
else									## Else if argument is not a specific file, assume it is a list of files.
	if	command -v file >> /dev/null && 								## If "file" is installed and...
		! file "${ARGUMENT}" | grep "ASCII text" >> /dev/null; then					## list file is not ascii text (as expected).
			echo -e "${RED}Error:${RESET} Bad backup list file (expecting ascii text file)."	## Then print usage and exit.
			echo -e "${USAGE}"
			QUIT ${BAD_LIST_FILE}
	else
		echo -e "\nBackup list is \"$ARGUMENT\". Checking files..." > ${DEST}	## Else the argument is assumed a list of files (option -l or no option).
		while read -r LINE ; do							## Iterate for every line in the backup file list.
			STRIPPED_LINE=$(echo "${LINE}" | tr -s " " | tr -d "\t" | cut -d "#" -f 1)	## Strip the comments.
													## 1) Squash any repeated spaces into a single space.
													## (Can't delete in case filename has spaces)
													## 2) Delete any tabs.
													## 3) Delete content of the line from the first '#'.
			if [ "${STRIPPED_LINE}" ]; then 						## If there is anything left of the stripped line.
				if [ "$(echo "${STRIPPED_LINE}" | cut -b ${#STRIPPED_LINE})" == " " ]; then			## If there is a trailing space left at the end...
					STRIPPED_LINE="$(echo "${STRIPPED_LINE}" | cut --complement -b ${#STRIPPED_LINE})"; fi	## Then delete the trailing space.
				FULL_PATH=${STRIPPED_LINE/#\~/$HOME}					## Expanded variable will be treated as a literal string.
				FULL_PATH=${FULL_PATH/\$HOME/$HOME}					## These two commands evaluate first "~" and then "$HOME"
													## then substitute either for the actual variable $HOME
													## Syntax: ${variable/string_match/replacement}

				for f in ${FULL_PATH}; do						## Loop to capture usecase that includes a wildcard '*' in FULL_PATH
					if [ -e "${f}" ]; then						## If the stripped and expanded line exists as a file
						echo -e "Adding: ${GREEN}${f}${RESET}" > ${DEST}	## Say so and then
						echo "${f}" >> "${TEMP_BU_FILE_LIST}"			## copy the stripped/expanded line to the temp file.
					else	echo -e "Failed: ${RED}${f}${RESET} does not exist and will be skipped"; fi	## Else skip the line.
				done
			fi
		done < "${ARGUMENT}"
		if [ ! -e "${TEMP_BU_FILE_LIST}" ]; then						## If the temp list file was not created
			echo -e "${RED}Error: ${RESET}The list file did not list any valid files."	## Then it didn't contain any valid files.
			echo -e "${USAGE}"								## So print usage and exit.
			QUIT "${NO_VALID_FILES}"; fi
	fi
fi

##########Run the sync.
echo > ${DEST}	## Log file will show rsync was attempted.
{
	echo -e "$(TIMESTAMP) - Attempting rsync backup to ${BU_SERVER}..."
	echo -e "-------------File list:-------------"
	cat ${TEMP_BU_FILE_LIST}
	echo -e "------------------------------------"
 } >> "${BU_LOG_FILE}"

if [ "${QUIET_MODE}" != "TRUE" ]; then echo -e "${BLUE}Using rsync to copy listed files to \"${RESET}${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/${BLUE}\"${RESET}"; fi
if ! rsync -4 --recursive --relative --verbose --human-readable --progress --archive --files-from="${TEMP_BU_FILE_LIST}" / "${BU_USER}@${BU_SERVER}:${BU_REMOTE_DIR}/" > ${DEST}; then
	echo -e "${RED}Error:${RESET} Sync failed."	## If rsync failed
	QUIT "${RSYNC_FAILED}"
else	
	echo -e "${GREEN}Success.${RESET}"			
fi

##########Delete the temp file.
rm "${TEMP_BU_FILE_LIST}"

##########All done.
echo -e "\n${GREEN}Success:${RESET} Script complete.\n" > ${DEST}
QUIT "${SUCCESS}"
