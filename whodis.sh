#!/bin/bash

## This script grabs the /tmp/dhcp.leases from a defined host (likely a router) and outputs the prettified content to screen.

ROUTER="root@192.168.1.1"				#Define the user and hostame of the router.

ssh $ROUTER "cat /tmp/dhcp.leases" > TEMPFILE_1		#Connect to the router and cat the dhcp.leases file.  Store to local temp file.

while read row; do					# Loop through each row in the temp file.

DATE=$(date --date=@"$(echo ${row} | cut -d " " -f 1)" +%Y-%m-%d)
TIME=$(date --date=@"$(echo ${row} | cut -d " " -f 1)" +%T)
MAC=$(echo ${row} | cut -d " " -f 2)
IP=$(echo ${row} | cut -d " " -f 3)
HOSTNAME=$(echo ${row} | cut -d " " -f 4)

echo "${DATE} ${TIME} ${MAC} ${IP} ${HOSTNAME}" >> TEMPFILE_2	# Write to second temp file.

done <TEMPFILE_1


sed -i "1i DATE TIME MAC IP HOSTNAME" TEMPFILE_2	# Append column headings to the top of the temp file ("1i" puts the text at row 1)

echo
column -t TEMPFILE_2					# Print the file to stdout with column for nice formatting.
echo

rm TEMPFILE_1 TEMPFILE_2				# Clean up, delete the temp files.

exit 0

