#  INSTRUCTIONS
# 
#  1. Rename this file to: config.sh
#  2. Configure this file according to your own preferences and setup
#  
#  That's it! Remember, this file will be used both on the bootstrapper
#  machine that writes the SD card and on the new Raspberry Pi.
#  It will then be deleted after setup is complete (before the first reboot).


# IMPORTANT! Public key string from which to allow login without password
# Leave blank to use the default: ~/.ssh/id_rsa.pub
# (Make sure this is the actual public key, not a file path)
AuthorizedPubKey=""

# Time zone, according to: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TimeZone="America/Denver"

# Filename of the Raspbian image to download, minus extension (tested on: "2013-07-26-wheezy-raspbian")
DownloadFilenameNoExt="2013-07-26-wheezy-raspbian"

# Full URL of the Raspbian image file, using the above filename
DownloadURL="http://files.velocix.com/c1410/images/raspbian/$DownloadFilenameNoExt/$DownloadFilenameNoExt.zip"

# If downloading a Raspbian image, whether to delete it when done ("y" or "n", or leave empty to be prompted)
DeleteWhenDone=""

# The default username for Raspbian login; leave blank for default: "pi"
DefaultUsername=""

# The default password for Raspbian login; leave blank for default: "raspberry"
DefaultPassword=""

# The home directory for the root user on the host (bootstrapper) system
# Leave blank to use the default: /var/root
RootHome=""

# Your home directory on the bootstrapper system
# (This is detected automatically; leave blank to use detected value)
UserHome=""

# New password for user "pi". Leave empty to keep default: raspberry
NewPassword=""

# If false, allows login only by SSH key; true will also let you type the password
AllowPasswordLogin=false

# SSH listener port (usually 22)
SSHPort=22

# Wifi network SSID (leave blank to not configure wifi)
WifiSSID=""

# Wifi network password
WifiPassword=""

# Any other packages you want installed with apt-get (separate with spaces)
CustomPackages="usbmount lynx"
