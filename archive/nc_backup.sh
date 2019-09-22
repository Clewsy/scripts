#!/bin/bash

## Bash script intended for backing up a nextcloud installation, inclusive of config and data files.
## Call as a cronjob to automate. E.g.:
# 0 1 * * * /usr/local/bin/nc_backup.sh
## This will run the script daily at 0100hrs.

## Define alternate output style.
BOLD="\033[01;37m"
RESET="\033[0m"

## Destination directory for backup files.
NC_BACKUP_DIR="/home/b4t/nc_backup"

## Directories to be included in the backup.
TO_BACKUP=(
"/var/www/html/nextcloud/"
"/etc/apache2/"
)

## Enter the working directory.
echo -e "\n${BOLD}Backup destination directory:${RESET}"
if ! cd "${NC_BACKUP_DIR}"; then	echo -e "${NC_BACKUP_DIR} not found.  Quitting." && exit 1
else					echo -e "${NC_BACKUP_DIR}"; fi

## Freeze nextcloud (maintenance mode).
echo -e "\n${BOLD}Entering Nexcloud mainteance mode.${RESET}"
sudo -u www-data php7.1 /var/www/html/nextcloud/occ maintenance:mode --on

## Run the rsync command for every directory listed in "TO_BACKUP".
for FOLDER in "${TO_BACKUP[@]}"
do
	if [ -d "${FOLDER}" ]; then	## Only rsync the directory if it exists and is, in fact, a directory.
		echo -e "\n${BOLD}Syncing folder: ${FOLDER}${RESET}"
		rsync --acls --archive --relative --verbose --one-file-system --delete --human-readable --progress "${FOLDER}" "${NC_BACKUP_DIR}"
	else
		echo -e "\n${BOLD}Skipping \"${FOLDER}\" (not found).${RESET}"
	fi
done

## Take a snapshot of the nextcloud database.
echo -e "\n${BOLD}Copying nextcloud database.${RESET}"
echo -e "nextcloud-sqlbkp_$(date +"%Y%m%d").bak"
sudo mysqldump --single-transaction -hlocalhost nextcloud > "nextcloud-sqlbkp_$(date +"%Y%m%d").bak"
## Note: for the above mysqldump to work with out options -u [user] -p[password], the home directory must contain the following file:
## File: ~/.my.cnf
## Contents:
# [mysqldump]
# user=root
# password=thesecretpassword
## Ensure access to my.cnf is restricted:
# sudo chmod 600 ~/.my.cnf

## Remove archived databases older than 30 days.
echo -e "\n${BOLD}Deleting database backup files older than a month.${RESET}"
find nextcloud-sqlbkp* -mtime +30 -delete

## Resume nextcloud.
echo -e "\n${BOLD}Exiting Nexcloud maintenance mode.${RESET}"
sudo -u www-data php7.1 /var/www/html/nextcloud/occ maintenance:mode --off

## All done
echo -e "\n${BOLD}Done.\n${RESET}"
