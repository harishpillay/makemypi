#!/bin/bash

# PLEASE READ CAREFULLY:
# THIS SCRIPT WILL BE AUTOMATICALLY EXECUTED AFTER BEING COPIED TO THE PI
# WILL BE RUN AS ROOT
# EXPECTING RASPBIAN IMAGE; TESTED ON WHEEZY
# PLEASE REVIEW THE CONFIGURE SECTION AND MAKE CHANGES AS NECESSARY


###############
#  CONFIGURE  #
###############

# Leave this alone (usually) -- it's the home directory of the default user "pi"
PiHome=$(eval echo ~${SUDO_USER})

# Time zone, according to: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TimeZone="America/Denver"

# New pi password. Leave empty to keep default. Default: raspberry
NewPassword=""

# Change to true to allow password login instead of just SSH key
AllowPasswordLogin=false

# SSH listener port (default 22)
SSHPort=5926

###################
#  END CONFIGURE  #
###################




if [[ $EUID -ne 0 ]]; then
	echo "Must be root. Aborting."
	exit
fi

# Move into the Pi's home directory
cd $PiHome

# Ask the user for the start of the main partition; looks like this:
# /dev/mmcblk0p2          122880     3788799     1832960   83  Linux
# They'd enter the first number (122880, from 2013-07-26 Raspbian Wheezy; varies)
echo -ne "\007"
startingSector=-1
sure="n"
while [ $sure != "y" ]
do
	fdisk -l
	echo
	echo
	echo "Preparing to extend the root partition to fill all SD card space."
	echo "The main partition is usually /dev/mmcblk0p2, and on 2013-07-26 Wheezy it starts at 122880."
	echo
	echo
	echo -n "Enter start of main partition: "
	read startingSector
	echo -n "You entered $startingSector. Are you sure? [y/n]: "
	read sure
done

# Install stuff
apt-get update
apt-get install htop expect screen -y
apt-get autoremove -y && apt-get clean

# Delete pre-loaded stuff we won't use
rm -rf ocr_pi.png Desktop/*.desktop python_games

# Establish some helpful aliases
echo "alias ll=\"ls -la\"" >> .bash_aliases
echo "alias echoip=\"curl -s echoip.com && echo\"" >> .bash_aliases
echo "alias locip=\"hostname -I\"" >> .bash_aliases
echo "alias temp=\"vcgencmd measure_temp\"" >> .bash_aliases
source .bash_aliases

# Set the local time zone
service ntp start
echo $TimeZone > /etc/timezone
echo "Setting local time zone to $TimeZone..."
dpkg-reconfigure -f noninteractive tzdata

# Prepare the .ssh directory
mkdir -p .ssh
chmod 700 .ssh

# Load and save the public key into the authorized_keys file so the sysadmin can log in
AuthorizedPubKey="`cat authorized_key`"
if [ "$AuthorizedPubKey" ]; then
	echo $AuthorizedPubKey >> .ssh/authorized_keys
	chmod 600 .ssh/authorized_keys
fi
rm -f authorized_key

# Save the SSH private and public key pair as id_rsa
if [ -e id_rsa ]; then
	mv -f id_rsa .ssh
	chmod 600 .ssh/id_rsa
fi
if [ -e id_rsa.pub ]; then
	mv -f id_rsa.pub .ssh
	chmod 644 .ssh/id_rsa.pub
fi

# Only allow login with private key?
if [ ! $AllowPasswordLogin ]; then
	sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config
fi

# Change SSH port and restart ssh
sed -i "s/Port 22/Port $SSHPort/" /etc/ssh/sshd_config
service ssh restart


# Change pi password (first line is the current/default password)
defaultPassword="raspberry"
if [ "$NewPassword" != "$defaultPassword" ] && [ "$NewPassword" ]; then
passwd pi <<EOI
$defaultPassword
$NewPassword
$NewPassword
EOI
fi


# Execute custom install steps.
if [ -e custom.sh ]; then
	echo "Executing custom installation steps..."
	chmod +x custom.sh
	./custom.sh
	echo "Finished executing custom installation steps."
fi


# SSH stuff belongs to pi, not root
chown -R pi:pi .ssh .bash_aliases

# Delete the built-in script that reminds us to configure the Pi
rm -f /etc/profile.d/raspi-config.sh

# Use fdisk to re-allocate the root partition
chmod +x autofdisk.exp resize.sh
./autofdisk.exp /dev/mmcblk0 $startingSector
sed -i 's/exit 0//g' /etc/rc.local
echo "$PiHome/resize.sh" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

# Delete used setup files, including this one and the template file in case it exists
rm -f setup.sh custom.sh custom_template.sh autofdisk.exp

# Bell; then reboot
echo -ne "\007"
echo
echo " ***  ALL DONE!"
echo " ***  REBOOTING TO FINISH SETUP."
echo " ***  COME BACK TO VISIT ANY TIME WITH:"
echo
echo "      ssh pi@`hostname -I`-p $SSHPort"
echo

reboot
