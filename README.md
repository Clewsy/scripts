# scripts

## active:

### bu.sh

Uses rsync to back up files and directories in a list file to a remote server.  Falls back to scp if rsync is not installed.

### stuff.sh

Pulls and lists a bunch of useful (to me) info about the host (hardware, disks/mounts, OS, network).

### vpn.sh

Kills current openvpn service then reconnects and confirms.  Useful for quickly re-establishing connection if it goes bad.

### wami.sh

Pulls and displays info (IP, country, city, etc) from "ipinfo.io" - useful to verify vpn operation.

### power_switch.sh

Written for use with termux (android) to connect to a server that can control wireless mains outlets via [p0wer](https://gitlab.com/Clewsy/p0wer).

### ball.sh

Runs bu.sh on a bunch of remote host or list of hosts.

### apt_all.sh

Runs apt-get update, apt-get dist-upgrade, apt-get autoremove and apt-get autoclean on a provided host or list of hosts.

### pong.sh

Runs through a list of servers, pings each once for a second then returns a success or fail result.

### whodis.sh

Grabs the contents of the /tmp/dhcp.leases file on a remote router, pretties it up and prints it to stdout.

### roll_out.sh

Attempt to copy a specified file/directory to a destination (relative to home directory) on a list of remote hosts.

### polly.sh

Called as a cronjob to regularly poll a web site and check the return code.  Logs site status to file and uses a [blink(1)](https://blink1.thingm.com/) as a visual status indicator.

## archived:

### grab.sh

Uses rsync (to allow resume after interruption) to download a specified file from a remote server.  No longer used.

### chuck.sh

Very similar to grab.sh, but used to upload to the remote server.  No longer used.

### cal_backup.sh

Generates an \*.ics file from a nextcloud calendar and archives it.  Intended to be used as a cronjob.  No longer used since moving nextcloud to a docker container.

### nc_backup.sh

A script to create a local backup of a nextcloud instance including the database, data files and config files.  To be called as a cronjob.  (A separate cronjob on a remote system syncs this local backup to create a remote backup.)  No longer used since moving nextcloud to a docker container.

### ytdl.sh

Written for use with termux (android) to download a youtube video direct to the device.  Archived as I no longer use this since switching to [LineageOS](https://lineageos.org/) and running [NewPipe](https://newpipe.schabi.org/) instead of the youtube app.  Newpipe has direct download capability.
