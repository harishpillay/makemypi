#!/bin/bash

# makemypi
# https://github.com/mholt/makemypi
# by Matthew Holt

# BASIC INSTRUCTIONS (see README.md for more details):
#	
#   0) Create transfer/config.sh from transfer/config_template.sh
#	
#	1) Make sure your public key is in:
#		~/.ssh/id_rsa.pub
#	   or set the AuthorizedPubKey variable in config.sh
#	
#	2) Put:
#		id_rsa
#		id_rsa.pub
#	   into the "transfer" directory. These are, respectively, the private and
#	   public key belonging to the Raspberry Pi
#	
#	3) If you have custom setup/provisioning steps, use provision_template.sh
#	
#	4) You must cd into the directory of this file before running it
#	
#	5) $ chmod +x makemypi.sh
#	
#	6) $ sudo ./makemypi.sh [imgFile]
#	
#		The optional parameter, imgFile, is a path to the .img file to write onto the SD card.
#		If you don't specify one, the script can download and extract the file for you.





if [[ $EUID -ne 0 ]]; then
	echo "Must be root. Aborting."
	exit
fi

if [ ! -e transfer/id_rsa ] || [ ! -e transfer/id_rsa.pub ]; then
	echo "Missing transfer/id_rsa or transfer/id_rsa.pub files."
	echo "Please save private/public key belonging to the Pi in those files."
	echo "Aborting."
	exit
fi

if [ ! -e transfer/config.sh ]; then
	echo "Missing transfer/config.sh file."
	echo "Please use transfer/config_template.sh to create transfer/config.sh and try again."
	echo "Aborting."
	exit
fi


source transfer/config.sh


# Set some defaults, if necessary

if [ -z "$UserHome" ]; then
	UserHome=$(eval echo ~${SUDO_USER})
fi

if [ -z "$RootHome" ]; then
	RootHome="/var/root"
fi

if [ -z "$DefaultUsername" ]; then
	DefaultUsername="pi"
fi

if [ -z "$DefaultPassword" ]; then
	DefaultPassword="raspberry"
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
	echo "You're choosing /dev/disk$device."
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
ImgFile=$1
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
		wget $DownloadURL && unzip $DownloadFilenameNoExt.zip
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


echo 
echo "Card ejected."
echo -ne "\007"
#(say SD card is ready &); (say -v Whisper I own you &)

# Get the LAN IP address of the raspi
IpAddressBegin="192.168."
echo "Please use it to boot the Raspberry Pi on the local network before continuing."
if [ "$WifiSSID" ]; then
	echo " -->  Please plug in the wifi receiver and ethernet."
	echo " -->  You MUST plug in at least the network cable for this step"
	echo "      because wifi won't connect until setup is complete."
fi
echo -n "When booted: what is the local IP address of the Pi? $IpAddressBegin"
read IpAddressEnd
IpAddress=$IpAddressBegin$IpAddressEnd


# Remove any conflicting host keys from the known_hosts file so there's no "nasty" warnings
echo "Removing any old entries in known_hosts"
sed -n '/'"$IpAddress"'/!p' $RootHome/.ssh/known_hosts > $RootHome/.ssh/known_hosts_temp
mv -f $RootHome/.ssh/known_hosts_temp $RootHome/.ssh/known_hosts
sed -n '/'"$IpAddress"'/!p' $UserHome/.ssh/known_hosts > $UserHome/.ssh/known_hosts_temp
mv -f $UserHome/.ssh/known_hosts_temp $UserHome/.ssh/known_hosts
chown $SUDO_USER:staff $UserHome/.ssh/known_hosts

# Dump a copy of the public key used for login to a file so it can be transferred
if [ -z "$AuthorizedPubKey" ]; then
	AuthorizedPubKey="`cat $UserHome/.ssh/id_rsa.pub`"
fi
echo "$AuthorizedPubKey" > transfer/authorized_key

# Perform copy and setup operations on the pi remotely using expect
echo "Copying setup files and authentication keys to $IpAddress..."
chmod +x scptransfer.exp
./scptransfer.exp "$DefaultUsername" "$IpAddress" "$DefaultPassword"

# Once tranferred, copy of the public key is no longer needed
rm -f transfer/authorized_key

echo 
echo " ***  YOUR PI IS MADE."
echo " ***  Just allow a few minutes for it to reboot and resize."
echo

if [ "$WifiSSID" ]; then
	echo " ***  The wifi has been configured and should be connecting momentarily,"
	echo "      probably with a new IP address. You may unplug the ethernet at your leisure."
	echo
fi
