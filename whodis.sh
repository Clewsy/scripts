#!/bin/bash

ROUTER="root@192.168.1.1"				#Define the user and hostame of the router.

ssh $ROUTER "cat /tmp/dhcp.leases" > TEMPFILE_1		#Connect to the router and cat the dhcp.leases file.  Store to local temp file.

cut -d " " -f 1 --complement TEMPFILE_1 > TEMPFILE_2	#Cut out the first column from the temp file.
cut -d " " -f 4 --complement TEMPFILE_2 > TEMPFILE_1	#Cut out the fourth column from the temp file.
sed -i "1i MAC IP HOSTNAME" TEMPFILE_1			#Append column headings to the top of the temp file ("1i" puts the text at row 1)

echo
column -t TEMPFILE_1		#Print the file to stdout with column for nice formatting.
echo

rm TEMPFILE_1 TEMPFILE_2	#Clean up, delete the temp files.

exit 0
