# scripts

[**apt_all.sh**][link_repo_apt_all.sh]

Runs apt-get update, apt-get dist-upgrade, apt-get autoremove and apt-get autoclean on a provided host or list of hosts.

---

[**ball.sh**][link_repo_ball.sh]

Runs bu.sh on a bunch of remote host or list of hosts.

---

[**bu.sh**][link_repo_bu.sh]

Uses rsync to back up files and directories in a list file to a remote server.  Falls back to scp if rsync is not installed.

---

[**p0wer\_switch.sh**][link_repo_p0wer_switch.sh]

Written for use with [Termux][link_web_termux] to connect to a server that can control wireless mains outlets via [p0wer][link_gitlab_clewsy_p0wer].

---
[**polly.sh**][link_repo_polly.sh]

Called as a cronjob to regularly poll a web site and check the return code.  Logs site status to file and uses a [blink(1)][link_web_blink1] as a visual status indicator.

---

[**pong.sh**][link_repo_pong.sh]

Runs through a list of servers, pings each once for a second then returns a success or fail result.

---

[**stuff.sh**][link_repo_stuff.sh]

Pulls and lists a bunch of useful (to me) info about the host (hardware, disks/mounts, OS, network).

---

[**terbling.sh**][link_repo_terbling.sh]

Prints an ascii-art logo and some basic system info to the command line.

---

[**vpn.sh**][link_repo_vpn.sh]

Kills current openvpn service then reconnects and confirms.  Useful for quickly re-establishing connection if it goes bad.

---

[**wami.sh**][link_repo_wami.sh]

Pulls and displays info (IP, country, city, etc) from [ipinfo.io][link_web_ipinfo] - useful to verify vpn operation.

---

[**whodis.sh**][link_repo_whodis.sh]

Grabs the contents of the /tmp/dhcp.leases file on a remote router, does some basic formatting and prints it to stdout.

---

# archived:

[**cal\_backup.sh**][link_repo_archive_cal_backup.sh]

Generates an \*.ics file from a nextcloud calendar and archives it.  Intended to be used as a cronjob.  No longer used since moving nextcloud to a docker container.

---

[**chuck.sh**][link_repo_archive_chuck.sh]

Very similar to grab.sh, but used to upload to the remote server.  No longer used.

---

[**grab.sh**][link_repo_archive_grab.sh]

Uses rsync (to allow resume after interruption) to download a specified file from a remote server.  No longer used.

---

[**nc\_backup.sh**][link_repo_archive_nc_backup.sh]

A script to create a local backup of a nextcloud instance including the database, data files and config files.  To be called as a cronjob.  (A separate cronjob on a remote system syncs this local backup to create a remote backup.)  No longer used since moving nextcloud to a docker container.

---

[**roll_out.sh**][link_repo_archive_roll_out.sh]

Attempt to copy a specified file/directory to a destination (relative to home directory) on a list of remote hosts.  I used this to sync my custom scripts to a list of hosts.  Now deprecated as I manage this task with [Ansible][link_web_ansible].

---

[**ytdl.sh**][link_repo_Archive_ytdl.sh]

Written for use with [Termux][link_web_termux] to download a youtube video direct to the device.  Archived as I no longer use this since switching to [LineageOS][link_web_lineageos] and running [NewPipe][link_web_newpipe] instead of the youtube app.  Newpipe has direct download capability.

---

[link_repo_apt_all.sh]:apt_all.sh
[link_repo_ball.sh]:ball.sh
[link_repo_bu.sh]:bu.sh
[link_repo_p0wer_switch.sh]:p0wer_switch.sh
[link_repo_polly.sh]:polly.sh
[link_repo_pong.sh]:pong.sh
[link_repo_stuff.sh]:stuff.sh
[link_repo_terbling.sh]:terbling.sh
[link_repo_vpn.sh]:vpn.sh
[link_repo_wami.sh]:wami.sh
[link_repo_whodis.sh]:whodis.sh
[link_repo_archive_cal_backup.sh]:archive/cal_backup.sh
[link_repo_archive_chuck.sh]:archive/chuck.sh
[link_repo_archive_grab.sh]:archive/grab.sh
[link_repo_archive_nc_backup.sh]:archive/nc_backup.sh
[link_repo_archive_roll_out.sh]:archive/roll_out.sh
[link_repo_archive_ytdl.sh]:archive/ytdl.sh
[link_gitlab_clewsy_p0wer]:https://gitlab.com/clewsy/p0wer
[link_web_termux]:https://termux.com/
[link_web_blink1]:https://blink1.thingm.com/
[link_web_ipinfo]:https://ipinfo.io/
[link_web_lineageos]:https://lineageos.org/
[link_web_newpipe]:https://newpipe.schabi.org/
[link_web_ansible]:https://docs.ansible.com/
