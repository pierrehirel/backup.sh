# backup.sh
A Simple Bash Script To Backup Files To A Remote Machine

(C) Pierre Hirel 2015
Université de Lille, Sciences et Technologies
UMR CNRS 8207 UMET, Bat. C6
59650 Villeneuve d'Ascq, FRANCE

PURPOSE:
This script makes a backup of some folders from your local desktop computer,
towards a remote machine. By default, this script only copies new files
and files that were modified, using the program rsync.
If you deleted files on your local computer, they are NOT deleted on the remote machine.
Note that this script *DOES NOT SYNCHRONIZE* your local computer with the remote machine,
because it does not copy anything from the remote machine to your computer. It only
copies files from your computer towards the remote one.
In other words, this script "backups" your files to the remote machine.

REQUIREMENTS:
(1) you must have an account on the remote machine
    (see REMOTEADMIN to know who to contact to create your account)
(2) the remote machine must be accessible via the network
    (change "remote" below into the address of the target remote machine)

USAGE:
On first run, you may run this script with:
  bash backup.sh --install

Otherwise you may just run it simply with:
  bash backup.sh

If you wish to run in verbose mode:
  bash backup.sh --verbose
