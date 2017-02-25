#!/bin/bash

BOLD=`tput bold`
RESET=`tput sgr0`

#Use rsync to grab a file from a remote server
#The following rsync options are set:
#-v : verbose
#-h : human-readable output
#-z : compress file data
#--protect-args : allow for whitespace in filenames
#--progress : display total progress indicator
#--append : append data to file in case or interruption

echo
echo "Usage: $(basename $0) <REMOTE_FILE>"
echo "This usage will copy the specified file from b4t@b4t-net.ddns.net to the current working directory."
echo
echo "Alternatively, use \"$(basename $0)\" with no arguments to prompt for remote user, remote server, remote file (source) and local file (target)."

if [ ! -z "$1" ] ; then	#if an argument exists then it should be the file on the default remote server
	rem_file=$1	#set the remote file to the value input as the argument
	#echo "Command: rsync -avhz --progress --append $rem_user@$rem_server:$rem_file $loc_file"
	#rsync -vhz --progress --append b4t@b4t-net.ddns.net:$rem_file .
	rem_user=b4t
	rem_server=b4t-net.ddns.net
	loc_file=.
	echo
	echo "Username: $rem_user (default)"
	echo "Remote server: $rem_server (default)"
	echo "Remote file: $rem_file"
	echo "Local file: $loc_file (default)"
else	#if no argument is entered then request manual input for the remote server/file (source) info and the local file (target) info.
	echo
	read -p "Enter remote username: " rem_user        #request username for remote login
	if [ -z $rem_user ] ; then	#set the remote login username to "b4t" if none specified
		echo "No remote username set.  Using default"
		rem_user=b4t
	fi
	echo "Username: $rem_user"

	echo
	read -p "Enter remote server (default=b4t-net.ddns.net): " rem_server   #request server for remote login
	if [ -z $rem_server ] ; then	#set the remote server to "b4t-net.ddns.net" if none specified
		echo "No server name set.  Using default."
		rem_server=b4t-net.ddns.net
	fi
	echo "Server: $rem_server"

	echo
	read -p "Enter remote directory/file (source): " rem_file #request source file including location on remote server
	if [ -z $rem_file ] ; then
		echo "No target file entered.  Using default."
		rem_file="~/"
	fi
	echo "Remote (source) file: $rem_file"

	echo
	read -p "Enter local directory/file (target): " loc_file #request target file including location on local machine
	if [ -z $loc_file ] ; then
		echo "No local file set.  Using default."
		loc_file=.
	fi
	echo "Local (target) file: $loc_file"
fi

echo
echo "Command: ${BOLD}rsync -vhz --protect-args --progress --append $rem_user@$rem_server:"$rem_file" "$loc_file"${RESET}"

echo
rsync -vhz --protect-args --progress --append $rem_user@$rem_server:"$rem_file" "$loc_file"
echo

exit 0 
