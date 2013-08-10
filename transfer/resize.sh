#!/bin/bash

# TO BE EXECUTED BY SETUP.SH ONLY ONCE (AS ROOT)
# You will not manually execute this file.

# Finishes the fdisk procedure by resizing the partition to the file system
# as per the instructions here: http://elinux.org/RPi_Resize_Flash_Partitions
# After it runs successfully, remove it from startup so it only runs once.
# Make sure, if you change PiHome in config.sh to a non-blank (non-default)
# value, that you update the paths here, too.

resize2fs /dev/mmcblk0p2 && sed -i 's/\/home\/pi\/resize.sh//g' /etc/rc.local && rm -f /home/pi/resize.sh