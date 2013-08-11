#!/bin/bash

# You do not need to execute this script manually.
# This script will be automatically executed after being copied to the Pi.
# This script will, and must, be run as root.
# Tested for Raspbian Wheezy images only.


if [[ $EUID -ne 0 ]]; then
	echo "Must be root. Aborting."
	exit
fi

# We must be in the default user's (pi) home directory
PiHome=$(eval echo ~${SUDO_USER})
cd "$PiHome"
source config.sh

# Ask the user for the start of the main partition; looks like this:
# /dev/mmcblk0p2          122880     3788799     1832960   83  Linux
# They'd enter the first number (122880, from 2013-07-26 Raspbian Wheezy; varies)
echo -ne "\007"
startingSector=-1
sure="n"
while [ $sure != "y" ] && [[ $startingSector -lt 1 ]]
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

# Install important packages
echo "Installing required packages"
apt-get update
apt-get install htop expect screen wpasupplicant -y

# Install any other stuff the user would like
if [ "$CustomPackages" ]; then
	echo "Installing custom packages"
	apt-get install $CustomPackages -y
fi

echo "Cleaning up"
apt-get autoremove -y && apt-get clean

# Delete pre-loaded stuff we won't use
rm -rf ocr_pi.png Desktop/*.desktop python_games

# Establish some helpful aliases
echo "alias ll=\"ls -la\"" >> .bash_aliases
echo "alias echoip=\"curl -s echoip.com && echo\"" >> .bash_aliases
echo "alias locip=\"hostname -I\"" >> .bash_aliases
echo "alias temp=\"vcgencmd measure_temp\"" >> .bash_aliases
source .bash_aliases
echo "Created aliases"

# Set the local time zone
service ntp start
echo "$TimeZone" > /etc/timezone
echo "Setting local time zone to $TimeZone"
dpkg-reconfigure -f noninteractive tzdata

# Prepare the .ssh directory
echo "Configuring credentials"
mkdir -p .ssh
chmod 700 .ssh

# Load and save the public key into the authorized_keys file so the sysadmin can log in
AuthorizedPubKey="`cat authorized_key`"
if [ "$AuthorizedPubKey" ]; then
	echo "$AuthorizedPubKey" >> .ssh/authorized_keys
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

# Only allow login with private key, if configured as such
[[ $AllowPasswordLogin == false ]] && sed -i 's/PermitRootLogin yes/PermitRootLogin without-password/' /etc/ssh/sshd_config

# Change SSH port and restart ssh
sed -i "s/Port 22/Port $SSHPort/" /etc/ssh/sshd_config
echo "Restarting SSH"
service ssh restart


# Change pi password (first line is the current/default password)
if [ "$NewPassword" != "$DefaultPassword" ] && [ "$NewPassword" ]; then
	echo "Changing password..."
passwd pi <<EOI
$defaultPassword
$NewPassword
$NewPassword
EOI
	echo "Password changed."
fi


# Execute custom install steps.
if [ -e provision.sh ]; then
	echo "Executing custom installation steps..."
	chmod +x provision.sh
	./provision.sh
	echo "Finished executing custom installation steps."
fi


# SSH stuff belongs to pi, not root
chown -R pi:pi .ssh .bash_aliases

# Configure wifi
if [ "$WifiSSID" ]; then
	echo "Configuring wifi"
	wpa_passphrase "$WifiSSID" "$WifiPassword" >> /etc/wpa_supplicant/wpa_supplicant.conf
fi

# Delete the built-in script that reminds us to configure the Pi
rm -f /etc/profile.d/raspi-config.sh

# Use fdisk to re-allocate the root partition
echo "Preparing to resize root file system..."
chmod +x autofdisk.exp resize.sh
./autofdisk.exp /dev/mmcblk0 $startingSector
sed -i 's/exit 0//g' /etc/rc.local
echo "$PiHome/resize.sh" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

# Delete used setup files, including this one and the template filse in case they exist
echo "Doing a little cleanup..."
rm -f setup.sh config.sh config_template.sh provision.sh provision_template.sh autofdisk.exp

# Bell; then reboot
echo -ne "\007"
echo
echo " ***  ALL DONE!"
echo " ***  REBOOTING TO FINISH SETUP."
echo " ***  COME BACK TO VISIT ANY TIME WITH:"
echo
echo "      ssh pi@`hostname -I`-p $SSHPort"
echo
if [ "$WifiSSID" ]; then
	echo " -->  NOTE: The IP address will probably be different once using wifi"
	echo
fi

reboot
