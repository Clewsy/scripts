#!/bin/bash

usage="Usage: $basename $0 <backup file list>"

##Colours
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

#Exit codes
too_many_args=1
bad_file_list=2
no_rem_dir=3	#ssh command to create remote directory failed

bu_server="b4t.site"
bu_remote_dir="$HOME/file_cache/$HOSTNAME"

#Check valid usage.
if [ $# -gt 1 ]; then	#Check than no more than one argument is provided.
	echo -e "${RED}Too many arguments${RESET}"
	echo "$usage"
	exit $too_many_args
fi

bu_file_list=${1-"${HOME}/bin/bu.list"}	#First argument is the file name of the list of files to be backed up.
				#If argument not provided, set default. Syntax: parameter=${parameter-default}
echo
echo "Backup file list is \"$bu_file_list\""
#Validate the backup file list.
if [ ! -f "$bu_file_list" -o ! -r "$bu_file_list" ]; then	#If bu.list is not (!) a normal file (-f) or (-o) in is not (!) readable (-r)
	echo -e "${RED}Backup file list \"$bu_file_list\" not found, invalid file type or no read access.${RESET}"
	exit $bad_file_list
fi
echo -e "${GREEN}Backup file list \"$bu_file_list\" validated.${RESET}"

#Validate the backup folder or create if absent.
echo
echo "Checking for remote backup directory \"$bu_remote_dir\" on remote backup server \"$bu_server\" (will be created if absent)."
ssh $bu_server "mkdir -p $bu_remote_dir"	#Connects to the remote server and creates the directory to which bu files will be copied.
if [ "$?" -ne "0" ]; then			#Checks the exit code from the SSH command.  If not zero, then it failed.
	echo -e "${RED}Failed to create remote directory${RESET}"
	exit $no_rem_dir
fi
echo -e "${GREEN}Remote backup directory \"${bu_remote_dir}\" validated.${RESET}"
echo

while read bu_file ; do		##Loop to repeat commands for each file name entry in the backup file list ($bu_file_list)
        echo "--------"
	echo "File/Directory name as listed in \"${bu_file_list}\": $bu_file"		#Filename as read from backup file list
	full_path="${bu_file/#\~/$HOME}"				#Expanded variable will be treated as a literal string.
	full_path="${full_path/\$HOME/$HOME}"				#These two commands evaluate first "~" and then "$HOME"
									#then substitute either for the actual variable $HOME
									#Syntax: ${variable/string_match/replacement}
	echo "Expanded filename: \"${full_path}\""
	if [ ! -e "${full_path}" ]; then	#If file doesn't exist
		echo -e "${RED}File/Directory \"${full_path}\" does not exist.  Skipping...${RESET}"
		continue		#Exit the loop and restart for the next file in the list.
	fi
	echo "File/Directory \"${full_path}\" exists."
	echo -e "${GREEN}Backing up \"${full_path}\" to \"${USER}@${bu_server}:${bu_remote_dir}/$(basename ${full_path})\"${RESET}" 
	scp -r -B "${full_path}" "${USER}@${bu_server}:$bu_remote_dir/"
	if [ "$?" -ne "0" ]; then                       #Checks the exit code from the SCP command.  If not zero, then it failed.
		echo -e "${RED}Failed to copy ${full_path} to remote directory${RESET}"
		continue
	fi
	echo -e "${GREEN}Success.${RESET}"

done < "$bu_file_list"		##File read by the while loop which includes a list of files to be backed up.

echo
echo "Backup complete"
echo
exit 0
