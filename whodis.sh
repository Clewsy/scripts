#!/bin/bash

## This script grabs the /tmp/dhcp.leases from a defined host (likely a router) and outputs the prettified content to screen.

# Define the user and hostame of the router.
ROUTER="root@192.168.1.1"

# Connect to the router and cat the dhcp.leases file.  Store to local temp file.
ssh $ROUTER "cat /tmp/dhcp.leases" > TEMPFILE_1

# Loop through each row in the temp file.
while read -r row; do

	DATE=$(date --date=@"$(echo "${row}" | cut -d " " -f 1)" +%Y-%m-%d)	# Parse date
	TIME=$(date --date=@"$(echo "${row}" | cut -d " " -f 1)" +%T)		# Parse time
	MAC=$(echo "${row}" | cut -d " " -f 2)					# Parse MAC address
	IP=$(echo "${row}" | cut -d " " -f 3)					# Parse IP address
	NAME=$(echo "${row}" | cut -d " " -f 4)					# Parse hostname

	echo "${DATE} ${TIME} ${MAC} ${IP} ${NAME}" >> TEMPFILE_2		# Write to second temp file.

done < TEMPFILE_1

# Append column headings to the top of the temp file ("1i" puts the text at row 1)
sed -i "1i DATE TIME MAC IP HOSTNAME" TEMPFILE_2

# Print the file to stdout with column for nice formatting.
echo
column -t TEMPFILE_2
echo

# Clean up, delete the temp files.
rm TEMPFILE_1 TEMPFILE_2

exit 0

