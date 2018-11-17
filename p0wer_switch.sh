#!/data/data/com.termux/files/usr/bin/bash

## Termux script for use on phone or tablet.
## Connects to p0wer server over local network if available.
## If not available, attempts connection remotely.
## Once connected, runs $COMMAND
## Intended to run p0wer programme on p0wer server to switch on/off a selected mains point.

LOC_USER="b4t"			# User for attempting local network connection (faster).
LOC_SERVER="p0wer"		# Hostname fo rattempting local network connection.
REM_USER="b4t"			# User for attempting remote network connection (if local fails)
REM_SERVER="b4t.site"		# Hostname for remote network connection.
COMMAND="sudo p0wer d on"	# Command to run on server.

echo "Desired command on target: \"${COMMAND}\""
echo "Attempting local connection."
ssh -t ${LOC_USER}@${LOC_SERVER} "${COMMAND}"
if [ $? = '0' ]; then						# If local connection succeeds.
	echo "Command successfully sent locally."
else								# Local connection timed out.
	echo "Unable to make local connection.  Attempting remote connection"
	ssh -t ${REM_USER}@${REM_SERVER} "ssh -t ${LOC_USER}@${LOC_SERVER} "${COMMAND}""
	if [ $? = '0' ]; then					# If remote connection succeeds.
		echo "Command successfully sent remotely."
	else							# Remote connection timed out.
		echo "Unable to connect.  Quitting."
	fi
fi

