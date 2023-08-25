# scripts:
Script Name                                 | Description
--------------------------------------------|-----------------------------------
[**apt_all**][link_repo_apt_all]            | Runs apt-get update, apt-get dist-upgrade, apt-get autoremove and apt-get autoclean on a provided host or list of hosts.  Logs results to file.
[**p0wer\_switch**][link_repo_p0wer_switch] | Written for use with [Termux][link_web_termux] to connect to a server that can control wireless mains outlets via [p0wer][link_gitlab_clewsy_p0wer].
[**polly**][link_repo_polly]                | Called as a cronjob to regularly poll a web site and check the return code.  Logs site status to file and uses a [blink(1)][link_web_blink1] as a visual status indicator.
[**pong**][link_repo_pong]                  | Runs through a list of servers, pings each once for a second then returns a success or fail result.
[**sneak**][link_repo_sneak]                | Use rsync to pull the contents of a directory on a remote machine to the local machine.  Intended to be implemented as a cronjob to responsibly transfer files under limited bandwidth restrictions.
[**stuff**][link_repo_stuff]                | Pulls and lists a bunch of useful (to me) info about the host (hardware, disks/mounts, OS, network).
[**terbling**][link_repo_terbling]          | Prints an ascii-art logo and some basic system info to the command line.
[**vpn**][link_repo_vpn]                    | Kills current openvpn service then reconnects and confirms.  Useful for quickly re-establishing connection if it goes bad.
[**wami**][link_repo_wami]                  | Pulls and displays info (IP, country, city, etc) from [ifconfig.co][link_web_ifconfig] - useful to verify vpn operation.
[**whodis**][link_repo_whodis]              | Grabs the contents of the /tmp/dhcp.leases file on a remote router, does some basic formatting and prints it to stdout.

<br />  

# archived:
Script Name                                             | Description
--------------------------------------------------------|-----------------------
[**ball**][link_repo_ball]                              | Runs bu on a bunch of remote host or list of hosts.  Logs results to file.  Deprecated thanks to [Ansible][link_web_ansible].
[**bu**][link_repo_bu]                                  | Uses rsync to back up files and directories in a list file to a remote server.  Logs results to file.  Deprecated thanks to [Ansible][link_web_ansible].
[**cal\_backup.sh**][link_repo_archive_cal_backup.sh]   | Generates an \*.ics file from a nextcloud calendar and archives it.  Intended to be used as a cronjob.  No longer used since moving nextcloud to a docker container.
[**chuck.sh**][link_repo_archive_chuck.sh]              | Very similar to grab.sh, but used to upload to the remote server.  No longer used.
[**grab.sh**][link_repo_archive_grab.sh]                | Uses rsync (to allow resume after interruption) to download a specified file from a remote server.  No longer used.
[**nc\_backup.sh**][link_repo_archive_nc_backup.sh]     | A script to create a local backup of a nextcloud instance including the database, data files and config files.  Called as a cronjob.  No longer used since moving nextcloud to docker.
[**roll_out.sh**][link_repo_archive_roll_out.sh]        | Attempt to copy a specified file/directory to a destination (relative to home directory) on a list of remote hosts.  I used this to sync my custom scripts to a list of hosts.  Now deprecated as I manage this task with [Ansible][link_web_ansible].
[**ytdl.sh**][link_repo_ytdl]                           | Written for use with [Termux][link_web_termux] to download a youtube video direct to the device.  No longer used since since switching running [NewPipe][link_web_newpipe] instead of the youtube app.  Newpipe has direct download capability.  Also, from the command line, [yt-dlc][link_web_yt-dlc] is an improved downloader (forked from [youtube-dl][link_web_youtube-dl]).


[link_repo_apt_all]:apt_all
[link_repo_ball]:ball
[link_repo_bu]:bu
[link_repo_p0wer_switch]:p0wer_switch
[link_repo_polly]:polly
[link_repo_pong]:pong
[link_repo_sneak]:sneak
[link_repo_stuff]:stuff
[link_repo_terbling]:terbling
[link_repo_vpn]:vpn
[link_repo_wami]:wami
[link_repo_whodis]:whodis
[link_repo_ytdl]:ytdl
[link_repo_archive_cal_backup.sh]:archive/cal_backup.sh
[link_repo_archive_chuck.sh]:archive/chuck.sh
[link_repo_archive_grab.sh]:archive/grab.sh
[link_repo_archive_nc_backup.sh]:archive/nc_backup.sh
[link_repo_archive_roll_out.sh]:archive/roll_out.sh
[link_gitlab_clewsy_p0wer]:https://gitlab.com/clewsy/p0wer
[link_web_ansible]:https://docs.ansible.com/
[link_web_blink1]:https://blink1.thingm.com/
[link_web_ifconfig]:https://ifconfig.co/
[link_web_lineageos]:https://lineageos.org/
[link_web_newpipe]:https://newpipe.schabi.org/
[link_web_termux]:https://termux.com/
[link_web_youtube-dl]:https://github.com/ytdl-org/youtube-dl
[link_web_yt-dlc]:https://github.com/blackjack4494/yt-dlc
