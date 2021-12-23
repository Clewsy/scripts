#!/bin/bash
#: Title:	: sneak
#: Author	: clewsy (clews.pro)
#: Description	: Use rsync to pull the contents of a directory on a remote machine to the local machine.
#:              : Intended to be ran as a cronjob so that the sync can be offset from peak usage where bandwidth is limited.
#:		: 0 2 * * * /home/user/bin/sneak	# Example crontab entry to run sneak every day at 0200 hours.
#: Options	: None (ignored).

########## Configurable settings.  SOURCE and TARGET can be overridden by arguments.
SOURCE="amy:/home/jc/transfer/"	## Format: user@host:/path/to/dir/ or host:/path/to/dir/ or /path/to/dir/
TARGET="/home/clewsy/transfer/"	## Format: As above.
RATE_LIMIT="100"		## Format: e.g. "100" for 100K, "1.5m" for 1.5M.

########## Exit codes
SUCCESS=0	## Noice.
#BAD_OPTION=1	## Invalid option.
ONLY_ONE_ARG=2	## Incorrect usage.
TOO_MANY_ARGS=3	## Incorrect usage.
BAD_LOGFILE=3	## Unable to write to the defined logfile directory.

########## Function to print current date and time.  Used for logging.
TIMESTAMP_f () { date +%Y/%m/%d\ %T; }

########## Function for exit conditions.  Log error or success and exit.
QUIT_f ()
{
	if [ "${1}" -gt 0 ]
		then	printf "%b%d%b"	"$(TIMESTAMP_f) ######### Script failed with error code " "${1}" ".\n" | tee -a ${SNEAK_LOG_FILE}
		else	printf "%b" 	"$(TIMESTAMP_f) ######### Script exited successfully.\n" | tee -a ${SNEAK_LOG_FILE}
	fi
#	printf "%b" "${SEPARATOR}${SEPARATOR}\n" >> "${SNEAK_LOG_FILE}"
	exit "${1}"
}

########## Usage
USAGE="
Usage examples:

${0##*/} <options> [source] [target]	## Manual use requires definition of both source and target.  Alternatively;
${0##*/} <options>			## Use the default source and target as defined in the script.

Valid options:
	-q	Quiet mode - only print the current host and the final summary.
	-v	Verbose mode - print additional info to stdout.  Overrides Quiet mode (\"-q\").
	-h	Print this usage and exit.
"

########## Define log file and ensure directory exists.
SNEAK_LOG_FILE="${HOME}/.log/sneak.log"
#SNEAK_LOG_FILE=".sneak.log"
if [ ! -w "${SNEAK_LOG_FILE%/*}" ]; then
	if ! mkdir --parents "${SNEAK_LOG_FILE%/*}" || ! touch "${SNEAK_LOG_FILE}"; then
		printf "%b" "${RED}Error:${RESET} Unable to create/write to the logfile (${SNEAK_LOG_FILE})\n";
		exit "${BAD_LOGFILE}";	## Don't use QUIT_f here because it will try to write to the log file.
	fi
fi


########## Interpret options
while getopts 'h' OPTION; do			## Call getopts to identify selected options and set corresponding flags.
	case "$OPTION" in
#		q)	QUIET=true ;;			## Set the quiet flag to suppress certain printf commands.
#		v)	DEST="/dev/stdout"		## -v activates verbose mode by sending output to /dev/stdout.
#			APT_GET_VERBOSITY=""		## Verbose mode removes the "--quiet" option with apt-get commands.
#			QUIET=false ;;			## Override Quiet mode option.
		h)	printf "%b" "${USAGE}\n"	## -h option just prints the usage then quits.
			QUIT_f "${SUCCESS}" ;;		## Exit successfully.
#		?)	printf "%b" "${RED}Error:${RESET} Invalid option/s.\n ${USAGE}\n"	## Invalid option, show usage.
#			QUIT_f "${BAD_OPTION}" ;;	## Exit with error.
	esac
done
shift $((OPTIND -1))	## This ensures only non-option arguments are considered arguments when referencing $#, #* and $n.


######### Validate provided argument/s.
if [ $# -gt 5 ]; then		## If more than one argument is entered.
	printf "%b" "${RED}Error:${RESET} Too many arguments.\n${USAGE}\n"	## Print error message and usage.
	QUIT_f "${TOO_MANY_ARGS}"	## Exit.
fi

case "$#" in
	0)	printf "%b" "Using default source and target:\n" ;;
	1)	printf "%b" "Error: Must define both source and target.\n${USAGE}\n"
		QUIT_f ${ONLY_ONE_ARG} ;;
	2)	SOURCE=${1}
		TARGET=${2} ;;
	?)	printf "%b" "Error: Too many arguments.\n${USAGE}\n"
		QUIT_f "${TOO_MANY_ARGS}" ;;

esac

printf "%b" "Source: ${SOURCE}\n"
printf "%b" "Target: ${TARGET}\n"

########## Set ssh options to be used by the rsync connection.
SSH_OPTIONS=(	
#	-4					## Use IPV4 (alternatively, -6 for IPV6).
	"-o StrictHostKeyChecking=no"		## Disable user verification for connecting to unknown (not yet authenticated) host.
	"-o UserKnownHostsFile=/dev/null"	## Disable automatically saving "newly discovered" hosts to the known_hosts file.
	"-o BatchMode=yes"			## Disable password prompts and host key confirmation requests.
	"-o ConnectTimeout=15"			## Stop attempting the connection after specified number of seconds.
)
RSYNC_SHELL="ssh ${SSH_OPTIONS[@]}"		## For inserting into the rsync command with the remote shell ("--rsh=") option.

########## Set rsync options.
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




printf "%b" "$(TIMESTAMP_f) ######### Beginning sync.\n" | tee -a ${SNEAK_LOG_FILE}

#rsync --bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable -e "ssh -o StrictHostKeyChecking=no" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}
#rsync --bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable --partial-dir=.partial --rsh="ssh -o StrictHostKeyChecking=no" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}
rsync "${RSYNC_OPTIONS[@]}" --rsh="${RSYNC_SHELL}" ${SOURCE} ${TARGET}
#rsync --bwlimit=${RATE_LIMIT} --progress --verbose --archive --acls --human-readable --partial-dir=.partial --log-file=${SNEAK_LOG_FILE} --rsh="ssh -o StrictHostKeyChecking=no" ${SOURCE_HOST}:${SOURCE_DIR} ${TARGET_DIR}

printf "%b" "$(TIMESTAMP_f) ######### Sync complete.\n" | tee -a ${SNEAK_LOG_FILE}


