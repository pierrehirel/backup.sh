#!/bin/bash

### backup.sh
### (C) Pierre Hirel 2015
### Université de Lille, Sciences et Technologies
### UMR CNRS 8207 UMET, Bat. C6
### 59650 Villeneuve d'Ascq, FRANCE

### PURPOSE:
### This script makes a backup of some folders from your local desktop computer,
### towards a remote machine. By default, this script only copies new files
### and files that were modified, using the program rsync.
### If you deleted files on your local computer, they are NOT deleted on the remote machine.
### Note that this script *DOES NOT SYNCHRONIZE* your local computer with the remote machine,
### because it does not copy anything from the remote machine to your computer. It only
### copies files from your computer towards the remote one.
### In other words, this script "backups" your files to the remote machine.

### REQUIREMENTS:
### (1) you must have an account on the remote machine
###     (see REMOTEADMIN to know who to contact to create your account)
### (2) the remote machine must be accessible via the network
###     (change "remote" below into the address of the target remote machine)

### USAGE:
### On first run, it is recommended to run this script with:
###   bash backup.sh --install
### Otherwise you may just run it simply with:
###   bash backup.sh
### If you wish to run in verbose mode:
###   bash backup.sh --verbose

### List of folders from your home directory (/home/user/) to backup
### Add or remove the desired folders from this list
folders="bin Documents"

### Name of remote machine or NAS
remote="mymachine"

### Port for ssh access on remote machine
port=22

### Set name of administrator of the remote machine
REMOTEADMIN="Name (email@address)"

### Set parameters of rsync command (see rsync's manual for more info)
### a = archive mode (includes recursion into sub-folders)
### u = update files only
### k = copy links to directories
### z = compress files during transfer (saves network bandwidth)
arg="-aukz"
if [ "$1" = "--verbose" ] ; then
  ### Run in verbose mode
  arg="-aukvz"
fi

### If the port for ssh access is not the default (22), say it to rsync
if [ "${port}" != "22" ] ; then
  arg+=" -e 'ssh -p ${port}'"
fi

### If you deleted files on your desktop computer, and want to remove
### them on the remote machine, then uncomment the following line:
#arg+=" --delete-after"

### Name of current script
name="${0##*/}"

### Username on local computer (automatic detection)
u=$(whoami)
### Username on remote machine
### (modify if your remote login is different from your desktop computer)
v=$u

### If user runs this script with argument "--install", then:
### (1) copy current script to his/her directory ~/bin/
### (2) add cron job to his/her crontab
### (3) create RSA key for ssh login without password
if [ "$1" = "--install" ] ; then
  echo " __________________________________________________ "
  echo "     INSTALLATION:"
  echo "  The following steps will be performed:"
  echo "  (1) This script will be copied to the folder /home/${u}/bin/"
  echo "  (2) A cron job will be added to your crontab scheduler, "
  echo "      so that this script is executed every day at the given time."
  echo "  (3) A pair of RSA keys will be generated so you can login to ${remote}"
  echo "      without typing your password."
  echo ""
  echo "  Each step can be performed separately, or skipped."
  printf "\n  Do you agree to proceed? (y/n) "
  read answer
  if [ "$answer" != "y" ] ; then
    printf "  Installation cancelled.\n"
    echo " __________________________________________________ "
    exit
  fi
  
  ### Copy current script to ~/bin/ and make it executable
  printf "  (1) Copy bash script $name to /home/${u}/bin/ ? (y/n) "
  read answer
  if [ "$answer" = "y" ] ; then
    mkdir -p ~/bin
    cp  ${0}  /home/${u}/bin
    chmod +x ~/bin/$name
    printf " Done.\n\n"
  fi
  
  printf "  (2) Do you wish to add task to your crontab? (y/n) "
  read answer
  if [ "$answer" = "y" ] ; then
    printf "  <?> Enter the time to run the backup (HH MM): "
    read h m
    ### Fix hour and minutes if user leaved them blank
    if [ "$h" = "" ] ; then
      h=00
    fi
    if [ "$m" = "" ] ; then
      m=00
    fi
    ### Write current crontab to a temporary file
    crontab -l > tmp.cron
    a=$(grep "$name" tmp.cron | wc -l)
    if [ "$a" -eq "0" ] ; then
      ### Add job to crontab
      echo " $m $h  *   *   *    bash ~/bin/$name " >> tmp.cron
      ### Install new crontab
      crontab tmp.cron
      echo "      Crontab was successfully updated."
      echo "      $name will run every day at $h:$m."
    else
      echo "  /!\ WARNING: crontab already contains $name entry."
      printf "               Do you wish to replace it? (y/n) "
      read answer
      if [ "$answer" = "y" ] ; then
        printf "      Updating crontab ... "
        ### Remove all lines containing name of current script
        sed -i "/${name}/D" tmp.cron
        ### Add job to crontab
        echo " $m $h  *   *   *    bash ~/bin/$name " >> tmp.cron
        ### Install new crontab
        crontab tmp.cron
        printf "Done.\n"
        echo "      $name will run every day at $h:$m."
      else
        printf "      Crontab was not updated.\n"
      fi
    fi
    rm -f tmp.cron
  fi
  
  printf "  (3) Do you wish to generate RSA keys for ssh login without password? (y/n) "
  read answer
  if [ "$answer" = "y" ] ; then

    ### Check if user already has ssh keys
    if [ ! -e /home/${u}/.ssh/id_rsa ] ; then
      ssh-keygen -t rsa
    else
      printf "\n      Using existing RSA key found in /home/${u}/.ssh/id_rsa."
    fi
  
    ### Create folder .ssh on remote machine (may already exist)
    ssh $v@${remote} mkdir -p .ssh
  
    ### Add user's public key to authorized_key on remote machine
    cat /home/${u}/.ssh/id_rsa.pub | ssh $v@${remote} 'cat >> .ssh/authorized_keys'
  
    printf "\n      RSA key successfully installed.\n"
  fi
  
  echo " __________________________________________________ "
  exit
fi

if [[ "$#" -gt 0 ]] ; then
  ### User tried to use arguments, can't understand them
  echo "X!X ERROR: illegal command-line arguments."
  exit
fi

### Test if remote machine is up and running
nc -z ${remote} ${port} > /dev/null
if [ $? != 0 ] ; then
  echo "  ERROR: unable to reach ${remote} on port ${port}."
  echo "         Remote machine may be down, unaccessible from this network, or you are using the wrong port."
  echo "         Please contact ${REMOTEADMIN}."
  exit
fi

### Test if user has ssh access and permission
ssh -q -o "BatchMode=yes" -i /home/${v}/.ssh/id_rsa ${v}@${remote} exit 2>/dev/null
if [ $? != 0 ] ; then
  echo "  ERROR: you do not seem to have ssh access to ${remote}."
  echo "         Please contact ${REMOTEADMIN} to create your account."
  exit
fi

### Go to user's home directory
cd ~

### Loop on all folders
echo " __________________________________________________ "
echo "    BACKUP TOWARDS  ${remote}"
for f in ${folders} ; do
  printf "  >>> Uploading folder: $f ..."
  if [ -d "$f" ] ; then
    rsync ${arg} /home/$u/$f/ $v@${remote}:/volume1/homes/$v/$f/
    printf " Done.\n"
  else
    printf " Folder does not exist on local machine, skipping.\n"
  fi
done

### Write current date and time into a file on remote machine
### (this is to know when your last backup was performed)
date | ssh $v@${remote} "cat > /var/services/homes/${v}/last_backup.txt"

echo " __________________________________________________ "
echo "    Backup finished."
date
echo ""

