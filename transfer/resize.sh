#!/bin/bash

# TO BE EXECUTED BY SETUP.SH ONLY ONCE (AS ROOT)

# Finishes the fdisk procedure by resizing the partition to the file system
# as per the instructions here: http://elinux.org/RPi_Resize_Flash_Partitions
# After it runs successfully, remove it from startup so it only runs once.

resize2fs /dev/mmcblk0p2 && sed -i 's/\/home\/pi\/resize.sh//g' /etc/rc.local && rm -f /home/pi/resize.sh