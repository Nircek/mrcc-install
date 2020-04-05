# mrcc-install
###### A simple script installing the Arch Linux

## Disclaimer
There is NO WARRANTY, to the extent permitted by law.
I'm not taking any responsibility for anything that this program does.
Please use it with caution.

## Usage
 - download [the latest version of Arch Linux live CD iso](https://www.archlinux.org/download/)
 - burn it to CD or write to a USB stick
 - reboot your PC and boot into Arch Linux live cd
 - wait until the system boots up
 - connect to the internet via Ethernet or Wi-Fi (you can use `wifi-menu` command)
 - download the `mrcc-install.sh` script by `curl -L nircek.github.io/mrcc-install/mrcc-install.sh > mrcc.install.sh` command
 - add the execute permission `chmod +x mrcc-install.sh`
 - execute the script by `./mrcc-install.sh` command in interactive mode or use `./mrcc-install -h` to display command-line parameters
 - follow the instructions on the screen

## Help message
```
USAGE: ./mrcc-install.sh <STATE> [OPTIONS]

There are several states:
  pre-install (default)
  install
  post-install

There are several options:
  -h display this help message
  -i non-interactive mode (don't ask for anything)
     if you want to use it, you must trigger at least:
     -L -e efi -a arch -s swap -A
  -L license agreement
  -l pre-install log file (default: ./log.txt)
  -F force when it is not an iso of Arch Linux
  -q quiet don't print to stdout log, only interactive things
  -e path to EFI device (e.g. /dev/sda1)
  -a path to device where Arch should be installed
  -s path to SWAP device
  -E format EFI device
  -A format ARCH device
  -S format SWAP device
  -w install wifi stuff
  -f post-install folder with mrcc stuff (default: /root/.mrcc)
  -r remove the mrcc folder when it isn't needed (will lost logs)
  -n computer name (default: ARCH-MRCC-<MRCCtime>)
  -x final command to be executed after install (e.g. "shutdown 0",
     "reboot" or "exit", default: "shutdown 0")\
  -b install timeshift and make a backup after installation

Exit codes:
   1 license disagreement
   2 not EFI environment
   3 not iso of an Arch Linux and not forced
   4 -i without needed parameters
   5 parse error
   6 no internet access
```

## Examples
 - `./mrcc-install.sh` - launch default interactive mode
 - `./mrcc-install.sh -h` - display a help message
 - `./mrcc-install.sh -iLEAw -e /dev/sda4 -a /dev/sda5 -s /dev/sda8 -n "ARCH-LAPTOP" -x "reboot" -b` - example of a good command excuting non-interactive mode
