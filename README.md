makemypi
========

A script which makes you a Raspberry Pi just the way you want it



## What it does

I was tired of doing all these steps manually, so I automated the whole process:

- Downloads a Raspbian Wheezy OS image file if you don't have one already
- Writes the OS image onto the SD card
- Configures the raspi's SSH credentials, including authorizing your own key so you can do key-based login
- Makes some common/convenient aliases:
	- `ll` (ls -la)
	- `echoip` (shows raspi's external IP address)
	- `locip` (shows raspi's local IP address)
	- `temp` (shows the CPU temperature)
- Sets the time zone
- Changes the default password (if you desire)
- Runs a script file with any custom commands as you please
- Resizes the root filesystem to expand to the whole available size of the SD card

I use my custom file to set up a few cron jobs and a simple web server for my own use.
What do you use yours for?



## How it works

It's nearly all automated. Just configure the script, insert an SD card, run the script, insert the SD card into
your raspi, type something, and the script will finish the setup process for you.



## How to make your Raspberry Pi

I hope you have a Mac, because I don't think this script will run on Windows or Linux. Oops! (Contribute?)

### Preparation

1. Clone down this repository (or [download the ZIP file](https://github.com/mholt/makemypi/archive/master.zip)).
2. Create or copy the public and private key pair belonging to your Raspberry Pi into the "transfer" folder.
   Call the files `id_rsa` for the private key, and `id_rsa.pub` for the public key.
3. Make sure your own public key is in `~/.ssh/id_rsa.pub`. Either that, or change the config variable near the top of
   [makemypi.sh](https://github.com/mholt/makemypi/blob/master/makemypi.sh).
4. Verify the "CONFIGURE" sections in both [makemypi.sh](https://github.com/mholt/makemypi/blob/master/makemypi.sh)
   and [transfer/setup.sh](https://github.com/mholt/makemypi/blob/master/transfer/setup.sh) are correct.
   **You will probably need to tweak the configuration.**
5. If you want to do custom setup steps, use
   [transfer/custom_template.sh](https://github.com/mholt/makemypi/blob/master/transfer/custom_template.sh).

### Running the script

1. In Terminal, `cd` into the directory containing [makemypi.sh](https://github.com/mholt/makemypi/blob/master/makemypi.sh).
2. `chmod +x makemypi.sh`
3. Plug in your SD card
4. `sudo ./makemypi.sh [imgFile]`
   
   The optional parameter, `[imgFile]`, is a path to the .img file to write onto the SD card.
   If you don't specify one, the script can download and extract the image file for you.




## More details

Files in the "transfer" folder get copied to the Raspberry Pi during the setup, but aren't guaranteed
to remain. In fact, all the setup files are removed once the setup is complete.

Use [transfer/custom_template.sh](https://github.com/mholt/makemypi/blob/master/transfer/custom_template.sh)
by renaming it to `custom.sh` and filling out your own custom commands. They'll
only be run once and won't have access to variables in
[setup.sh](https://github.com/mholt/makemypi/blob/master/transfer/setup.sh). Your custom commands will be run near
the end of the setup process, just before expanding the root filesystem to fill the SD card and rebooting.
(So you'll have more limited space than you might expect.)

Of course, this whole thing is open source, so you can change any part of the script you want. Feel free to fork
the project if you need to do it differently, or submit pull requests with bug fixes and improvements.


## Disclaimer

This script uses dd and some other "volatile" commands. I assume no responsibility if anything goes wrong
on your end. It works on my machine, but I don't know if it will work on yours. Sorry.
But have fun, and enjoy your Pi!