#!/bin/bash
#: Title:	: sneak
#: Author	: clewsy (clews.pro)
#: Description	: Use rsync to pull the contents of a directory on a remote machine to the local machine.
#:              : Intended to be ran as a cronjob so that the sync can be offset from peak usage where bandwidth is limited.
#: Options	: None (ignored).

##########Configurable settings.
SOURCE_HOST="amy"			## Format: user@host or alternatively just host as devined in ~/.ssh/config file.
SOURCE_DIR="/home/jc/transfer/"		## Format: /target/directory/ i.e. use trailing '/' to capture contents of directory.
TARGET_DIR="/home/clewsy/transfer/"	## Format: As above.
RATE_LIMIT="100"			## Format: e.g. "100" for 100K, "1.5m" for 1.5M.

#SOURCE_SERVER_REMOTE="clews.pro"
#SOURCE_REMOTE_DIR="/home/${BU_USER}/file_cache/${HOSTNAME}"

##########Define log file and ensure directory exists.
#SNEAK_LOG_FILE="${HOME}/.log/sneak.log"
SNEAK_LOG_FILE=".sneak.log"
#if [ ! -w "${SNEAK_LOG_FILE%/*}" ]; then
#	if ! mkdir --parents "${SNEAK_LOG_FILE%/*}" || ! touch "${SNEAK_LOG_FILE}"; then
#		printf "%b" "${RED}Error:${RESET} Unable to create/write to the logfile (${SNEAK_LOG_FILE})\n";
#		exit "${BAD_LOGFILE}";	## Don't use QUIT_f because it needs to write the logfile.
#	fi
#fi

SSH_OPTIONS=(	
#	-4					## Use IPV4 (alternatively, -6 for IPV6).
	"-o StrictHostKeyChecking=no"		## Disable user verification for connecting to unknown (not yet authenticated) host.
	"-o UserKnownHostsFile=/dev/null"	## Disable automatically saving "newly discovered" hosts to the known_hosts file.
	"-o BatchMode=yes"			## Disable password prompts and host key confirmation requests.
	"-o ConnectTimeout=15"			## Stop attempting the connection after specified number of seconds.
)
RSYNC_SHELL="ssh ${SSH_OPTIONS[@]}"

#RSYNC_OPTIONS="--bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable --partial-dir=.partial --log-file=${SNEAK_LOG_FILE} --rsh=\"ssh -o StrictHostKeyChecking=no\""
RSYNC_OPTIONS=(
	"--bwlimit=${RATE_LIMIT}"		## Set the max bandwidth that rsync will use.
	"--progress"				## Output info about current transfer status and progress.
	"--verbose=3"				## Output extra information.
	"--human-readable"			## Numbers output (e.g. progress info) are easily readable.
	"--partial-dir=.partial"		## Define directory to store partially transferred files.
	"--log-file=${SNEAK_LOG_FILE}"		## Define the logfile.
	"--archive"				## Archive mode.  Equivalent to -rlptgoD.
)						#### -r or --recursive	: Sync diectories, sub-directories and all contents.
						#### -l or --links	: Symlinks are copied as symlinks.
						#### -p or --perms	: File/directory permissions are preserved.
						#### -t or --times	: File/directory creation/modification times are preserved.
						#### -g or --group	: File/directory groups are preserved.
						#### -o or --owner	: File/directory owners are preserved (root only).
						#### -D			: Equivalent to --devices --specials
						###### 	--devices	: Sync character and block device files (root only).
						###### 	--specials	: Sync special files (e.g. named sockets and fifos).

echo "${SSH_OPTIONS[@]}"
echo "${RSYNC_SHELL}"
echo "${RSYNC_OPTIONS[@]}"

##########Function to print current date and time.  Used for logging.
TIMESTAMP_f () { date +%Y/%m/%d\ %T; }


##########Function for exit conditions.  Log error or success and exit.
QUIT_f ()
{
	if [ "${1}" -gt 0 ]; then	printf "%b%d%b" "$(TIMESTAMP_f) - Script failed with error code " "${1}" ".\n" >> "${SNEAK_LOG_FILE}"
	else				printf "%b" "$(TIMESTAMP_f) - Script exited successfully.\n" >> "${SNEAK_LOG_FILE}"; fi
	printf "%b" "${SEPARATOR}${SEPARATOR}\n" >> "${SNEAK_LOG_FILE}"
	exit "${1}"
}


##########Usage
USAGE="
Usage: ${0##*/} [option] [source] [target]
#TO DO: Fill in usage guidance.
"
#todo log start date/time


printf "%b" "$(TIMESTAMP_f) ######### Beginning sync.\n" | tee -a ${SNEAK_LOG_FILE}

#rsync --bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable -e "ssh -o StrictHostKeyChecking=no" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}
#rsync --bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable --partial-dir=.partial --rsh="ssh -o StrictHostKeyChecking=no" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}
rsync "${RSYNC_OPTIONS[@]}" --rsh="${RSYNC_SHELL}" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}
#rsync --bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable --partial-dir=.partial --log-file=${SNEAK_LOG_FILE} --rsh="ssh -o StrictHostKeyChecking=no" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}

printf "%b" "$(TIMESTAMP_f) ######### Sync complete.\n" | tee -a ${SNEAK_LOG_FILE}


#todo log end date/time
