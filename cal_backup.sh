#!/bin/bash

########bash script to export, name and archive a calendar *.ics file from nextcloud's calendar app.

##to automate, run "sudo crontab -u www-data -e" to edit the cron table for user www-data and enter the following (for example):
#0 0,12 * * * /usr/local/bin/bin/cal_backup.sh
##this will run the script at midnight and midday every day.
##Ensure this script is copied to the location above and is set to executable.
#sudo cp cal_backup.sh /usr/local/bin/cal_backup.sh
#sudo chmod +x /usr/local/bin/cal_backup.sh
##Note, by editing user www-data's crontab, the commands below will be executed by www-data (hence no need for sudo -u www-data)
##However, this means that to run this script manually, it must be prepended with sudo -u www-data.

##generate a user and password specifically for this script in nextcloud:
#settings->security->devices & sessions->create new app password
##define the user in accordance with the nextcloud access
USER="clewsy"
##define the password in accordance with the nextcloud access.
PASSWORD="passw-0rdPA-SSW0R-Dpass-w0rdP"

#define the calendar identifier.  you can find it within the url when you load the calendar in the nextcloud webui.
CALENDAR="9256b433-dcf8-4263-97ca-2d399d0a1c12"

##the filename to be used for saving the archived *.ics calendar file.  prepended by the date command to generate a timestamp.
FILENAME="$(date +%Y%m%d%H%M%S)_${USER}_calendar_backup.ics"

##define the local nextcloud root directory.
NEXTCLOUD_ROOT="/var/www/html/nextcloud"

##define the local directory in which the USER's nextcloud files are stored.
USER_FILES="${NEXTCLOUD_ROOT}/data/${USER}/files"

##define the local directory in which the *.ics backup will be stored.
DIRNAME=".Calendar-Backup"

##define the base url for your nextcloud instance.
NEXTCLOUD_URL="https://clews.pro/nextcloud"

##define the url to export the calendar to an *.ics file.
CALENDAR_URL="${NEXTCLOUD_URL}/remote.php/dav/calendars/${USER}/${CALENDAR}/?export"

##run the curl command to export, download and save the ics file.
##run as user www-data so that www-data remains the file owner.  this way the file can be r/w accessed within the nextcloud webui.
curl -o "${USER_FILES}/${DIRNAME}/${FILENAME}" -u "${USER}:${PASSWORD}" "${CALENDAR_URL}"

##delete any calendar backups older than a month
find ${USER_FILES}/${DIRNAME} -mtime +30 -delete

##do a directory-specific files:scan to so that the new ics file is entered into the nextcloud database
php7.1 ${NEXTCLOUD_ROOT}/occ files:scan --path "${USER}/files/${DIRNAME}"

