#!/bin/bash

# makemypi
# Automatically makes a Raspberry Pi by downloading an OS, writing it, installing stuff, and configuring it.
# By Matthew Holt (github.com/mholt/makemypi)

# YOU WILL EXECUTE THIS SCRIPT

# BASIC INSTRUCTIONS (see README for more up-to-date details):
#	0) Make sure your public key is in: ~/.ssh/id_rsa.pub (or change AuthorizedPubKey below)
#	1) Put an id_rsa and id_rsa.pub in the "transfer" directory which are, respectively,
#	   the private and public key belonging to the Raspberry Pi
#	2) Verify the configure section below is correct
#	3) Verify the configure section in transfer/setup.sh is correct
#	4) If you have custom setup steps, use custom_template.sh
#	5) You must cd into the directory of this file before running it
#	6) chmod +x install.sh
#	7) sudo ./install.sh [imgFile]
# The optional parameter is a path to the .img file to write onto the SD card.
# If you don't specify one, the script can download and extract the file for you.




###############
#  CONFIGURE  #
###############

# Filename of the Raspbian image to download, minus extension
DownloadFilenameNoExt="2013-07-26-wheezy-raspbian"

# Full URL of the Raspbian image file, using the above filename
DownloadURL="http://files.velocix.com/c1410/images/raspbian/$DownloadFilenameNoExt/$DownloadFilenameNoExt.zip"

# IMPORTANT! Public key from which to allow login without password (default: contents of ~/.ssh/id_rsa.pub)
AuthorizedPubKey="`cat $(eval echo ~${SUDO_USER})/.ssh/id_rsa.pub`"

# If downloading a Raspbian image, whether to delete it when done ("y" or "n", or leave empty to be prompted)
DeleteWhenDone=""

# Instead of downloading an image, you can pass in the path to a local .img file
ImgFile=$1

# The default username for Raspbian login; usually "pi"
DefaultUsername="pi"

# The default password for Raspbian login; usually "raspberry"
DefaultPassword="raspberry"

# The home directory for the root user on the host system. On a Mac, this is usually /var/root
RootHome="/var/root"

# Usually leave this alone; it's YOUR home directory, of the user that calls sudo
RegularHome=$(eval echo ~${SUDO_USER})

###################
#  END CONFIGURE  #
###################






if [[ $EUID -ne 0 ]]; then
	echo "Must be root. Aborting."
	exit
fi


# Show the user connected storage devices
df -h

# Prompt for the SD card device and partition, then confirm
sure="n"
device=0
partition=""
downloaded=false
while [ $sure != "y" ]
do
	echo
	echo -n "Enter SD card device number (e.g. for /dev/disk7s1, enter 7): "
	read device
	if [ $device == "q" ]; then
		exit
	fi
	echo "You chose /dev/disk$device."
	echo -n "Enter partition (e.g. for /dev/disk""$device""s1, enter s1): "
	read partition
	if [ $partition == "q" ]; then
		exit
	fi
	echo "You chose /dev/disk$device$partition."
	echo -n "Are you ABSOLUTELY sure? [y/n]: "
	read sure
	if [ $sure == "q" ]; then
		exit
	fi
done


# If no image file was specified as an argument, optionally download it and use it
if [ -z $ImgFile ]; then
	echo "No image file specified."
	echo "I'll download Raspbian Wheezy for you. It's a 518 MB download, and 2.5 GB disk space is needed."
	echo -n "Is that OK? [y/n]: "
	read goahead
	if [ $goahead == "y" ]; then
		downloaded=true
		if [ -z "$DeleteWhenDone" ]; then
			echo -n "Delete downloaded files when finished? [y/n]: "
			read DeleteWhenDone
		fi
		echo
		wget $DownloadURL
		unzip $DownloadFilenameNoExt.zip
		if [ "$DeleteWhenDone" == "y" ]; then
			rm -f $DownloadFilenameNoExt.zip
		fi
		ImgFile=`pwd`/$DownloadFilenameNoExt.img
	else
		echo "Nothing for me to do then. Aborting."
		exit
	fi
fi

# Make sure the image file exists
if [ ! -e $ImgFile ]; then
	echo "File $ImgFile does not exist."
	exit
fi

echo "Unmounting partition..."

diskutil unmountDisk /dev/disk$device

echo "Writing image file, please wait..."

dd bs=1m if=$ImgFile of=/dev/rdisk$device

echo "Ejecting device..."

diskutil eject /dev/rdisk$device

if [ $downloaded ] && [ "$DeleteWhenDone" == "y" ]; then
	rm -f $ImgFile
fi


echo "Card ejected."
echo -ne "\007"
#(say SD card is ready &); (say -v Whisper I own you &)

# Get the LAN IP address of the raspi
IpAddressBegin="192.168."
echo "Please use it to boot the Raspberry Pi on the local network before continuing."
echo -n "When it's ready: what is the local IP address of the Pi? $IpAddressBegin"
read IpAddressEnd
IpAddress=$IpAddressBegin$IpAddressEnd


# Remove any conflicting host keys from the known_hosts file so there's no "nasty" warnings
echo "Removing any old entries in known_hosts"
sed -n '/'"$IpAddress"' /!p' $RootHome/.ssh/known_hosts > $RootHome/.ssh/known_hosts_temp
mv -f $RootHome/.ssh/known_hosts_temp $RootHome/.ssh/known_hosts
sed -n '/'"$IpAddress"' /!p' $RegularHome/.ssh/known_hosts > $RegularHome/.ssh/known_hosts_temp
mv -f $RegularHome/.ssh/known_hosts_temp $RegularHome/.ssh/known_hosts
chown $SUDO_USER:staff $RegularHome/.ssh/known_hosts

# Dump a copy of the public key used for login to a file so it can be transferred
echo "$AuthorizedPubKey" > transfer/authorized_key

# Perform copy and setup operations on the pi remotely using expect
echo "Copying setup files and authentication keys to $IpAddress..."
chmod +x util/scptransfer.exp
util/scptransfer.exp $DefaultUsername $IpAddress $DefaultPassword

# Once tranferred, copy of the public key is no longer needed
rm -f transfer/authorized_key

echo 
echo " ***  YOUR PI IS MADE."
echo " ***  Just allow a few minutes for it to reboot and resize."
echo
