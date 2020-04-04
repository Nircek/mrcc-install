#!/usr/bin/env bash
# file from https://gist.github.com/Nircek/
# licensed under MIT license

# MIT License

# Copyright (c) 2019 Nircek

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

read -rd '' header << EOF
mrcc-install
Copyright (c) 2019 Nircek
under MIT License
EOF
read -rd '' short_license << EOF
There is NO WARRANTY, to the extent permitted by law.
I'm not taking any responsibility for anything that this program does.
Please use it with caution.
EOF
usage='USAGE: $0 <STATE> [OPTIONS]
use "$0 -h" for help'
read -rd '' help << EOF
USAGE: $0 <STATE> [OPTIONS]

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
  -n computer name (default: ARCH-MRCC-`date +"%-d%-m%y"`)
  -x final command to be executed after install (e.g. "shutdown 0",
     "reboot" or "exit", default: "shutdown 0")

Exit codes:
   1 license disagreement
   2 not EFI environment
   3 not iso of an Arch Linux and not forced
   4 -i without needed parameters
   5 parse error
   6 no internet access
EOF
interactive_mode=true
license=false
LOG_FILE="./log.txt"
force=false
quiet=false
efiformat=false
archformat=false
swapformat=false
wifiinstall=false
mrcc_folder="/root/.mrcc"
mrcc_remove=false
compname="ARCH-MRCC-`date +"%-d%-m%y"`"
finally="shutdown 0"
state="pre-install"

containsElement () {
  # https://stackoverflow.com/a/8574392/6732111
  local e match="$1"
  shift
  for e; do [ "$e" = "$match" ] && return 0; done
  return 1
}

states=(pre-install install post-install -h)
[ $# -gt 0 ] && { containsElement "$1" "${states[@]}" && { state="$1"; shift; } || { echo -e "error: there is no such state like \"$1\""; exit 5; } }
[ "$state" = "-h" ] && { echo -e "$header\n\n$short_license\n\n$help"; exit 0; }

args=( "$@" )

while getopts ":hiLl:Fqe:a:s:EASwf:rn:x:" opt
do
  case $opt in
    h) echo -e "$header\n\n$short_license\n\n$help"; exit 0;;
    i) interactive_mode=false;;
    L) license=true;;
    l) LOG_FILE="$OPTARG";;
    F) force=true;;
    q) quiet=true;;
    e) efidisk="$OPTARG";;
    a) archdisk="$OPTARG";;
    s) swapdisk="$OPTARG";;
    E) efiformat=true;;
    A) archformat=true;;
    S) swapformat=true;;
    w) wifiinstall=true;;
    f) mrcc_folder="$OPTARG";;
    r) mrcc_remove=true;;
    n) compname="$OPTARG";;
    x) finally=( "$OPTARG" );;
    \?) echo -e "error: invalid option: -$OPTARG\n$usage" >&2; exit 5;;
    :) echo -e "error: option -$OPTARG requires an argument\n$usage" >&2; exit 5;;
  esac
done

shift $(( OPTIND - 1 ))
[ $# -gt 0 ] && { echo -e "error: too many arguments\n$usage" >&2; exit 5; }


if ! $interactive_mode
then
  error () { echo "error: non-interactive mode is on but '$1' option is not provided" >&2; exit 4; }
  [ "$license" = "false" ] && error -L
  [ -z "$efidisk" ] && error -e
  [ -z "$archdisk" ] && error -a
  [ -z "$swapdisk" ] && error -s
  [ "$archformat" = "false" ] && error -A
fi

choice () {
  [ "$interactive_mode" = "false" ] && return 2
  echo -n "$@ [y/n] "
  while [ true ]
  do
    read -rsn1 key
    if [ $key = 'y' ] || [ $key = 'Y' ]
    then
      echo y
      return 0
    elif [ $key = 'n' ] || [ $key = 'N' ]
    then
      echo n
      return 1
    fi
  done
}

choice-no () {
  choice "$@"
  r=$?
  [ $r -eq 2 ] && { return 2; } || { [ $r -eq 0 ] && return 1 || return 0; }
}

timed () {
  echo "`date +"[%Y-%m-%d %H:%M:%S]"`> $@"
}

log () {
  [ "$1" = "-q" ] && { arg="-q"; shift; } || arg=""
  [ "$quiet" = "false" ] && arg=""
  [ -z "$arg" ] && { timed "$@" | tee -a $LOG_FILE; } || { timed "$@" >> $LOG_FILE; }
}

trace () {
  [ "$1" = "-q" ] && { arg="-q"; shift; } || arg=""
  [ "$quiet" = "false" ] && arg=""
  log $arg "$""$@"
  [ -z "$arg" ] && { "$@" 2>&1 | tee -a $LOG_FILE; r=${PIPESTATUS[0]}${pipestatus[1]}; } || { "$@" &>> $LOG_FILE; r=$?; }
  log $arg "$r"
  return $r
}

trace-file () {
  # argument: $file
  [ "$1" = "-q" ] && { arg="-q"; shift; } || arg=""
  [ "$quiet" = "false" ] && arg=""
  log $arg "$""$@ >> $file"
  [ -z $arg ] && { "$@" >> "$file" 2>&1 | tee -a $LOG_FILE; r=${PIPESTATUS[0]}${pipestatus[1]}; } || { "$@" >> "$file" 2>> $LOG_FILE; r=$?; }
  log $arg "$r"
  return $r
}

internet () {
  ping 8.8.8.8 -c1 > /dev/null
}

init2 () {
  exit () {
    log "Exit with code: $@"
    command exit "$@"
  }
}

[ "$state" = "pre-install" ] && {
  echo -e "$header\n\n$short_license\n"
  ! "$license" && { ( "$interactive_mode" && choice "Do you accept this?" ) || exit 1; }
  log -q "Started logging"
  init2
  [ -d /sys/firmware/efi ] || { log "This is not EFI. Sorry."; exit 2; }
  good="is"
  bad () { good="is NOT"; }
  archiso="`find /dev/disk/by-label/ARCH_* -printf "%f\n" 2>/dev/null`" || { bad; archiso="UNKNOWN"; }
  pacman="`pacman -Q linux 2>/dev/null`" || { bad; linux="NO PACMAN"; }
  [ "`uname -s`" = "Linux" ] && [ "`uname -o`" = "GNU/Linux" ] && linux="`uname -sr`" || { bad; linux="NO LINUX"; }
  name="`uname -n`"
  [ "$name" = "archiso" ] || bad
  log -q "Your version of system is $archiso."
  log -q "Found $linux by uname and $pacman by pacman."
  log -q "The nodename is $name."
  log "I think it $good an iso of Arch Linux."
  ( [ "$good" != "is" ] && ! "$force" ) && { ( "$interactive_mode" && choice "Do you REALLY want to continue?" ) || exit 3; }
  trace -q loadkeys pl
  trace -q setfont lat2-16.psfu.gz -m 8859-2
  internet || { echo "error: you have to have an internet access"; exit 6; }
  trace -q timedatectl set-ntp true && sleep 5
  trace -q timedatectl status
  "$interactive_mode" && trace fdisk -l || trace -q fdisk -l
  while "$interactive_mode"
  do
    echo "Make 3 partitions: EFI (EF00), EXT4 and SWAP."
    read -p"Type the name of your device (or ':' to go next): " disk
    [ "$disk" = ":" ] && break
    trace gdisk $disk
    fdisk -l
  done
  [ -z "$efidisk" ] && "$interactive_mode" && read -p"Type the name of your EFI partition: " efidisk
  ( "$efiformat" || ( "$interactive_mode" && choice "Do you want to format it?" ) ) && trace -q mkfs.vfat "$efidisk"
  first=true
  while "$interactive_mode" || "$first"
  do
    [ -z "$archdisk" ] && "$interactive_mode" && read -p"Type the name of your EXT4 partition: " archdisk
    ( "$efiformat" || ( "$interactive_mode" && choice "I will format it." ) ) && { trace -q mkfs.ext4 "$archdisk"; break; }
    first=false
  done
  [ -z "$swapdisk" ] && "$interactive_mode" && read -p"Type the name of your SWAP partition: " swapdisk
  ( "$swapformat" || ( "$interactive_mode" && choice "Do you want to format it?" ) ) && trace -q mkswap "$swapdisk"
  trace -q swapon "$swapdisk"
  trace -q mount "$archdisk" /mnt
  trace -q mkdir /mnt/boot
  trace -q mount "$efidisk" /mnt/boot
  adds=""
  ( "$wifiinstall" || ( "$interactive_mode" && choice "Do you want to install Wi-Fi stuff?" ) ) && adds="wpa_supplicant dialog netctl dhcpcd"
  echo "Installing..."
  trace -q pacstrap /mnt base linux linux-firmware $adds
  file="/mnt/etc/fstab"
  trace-file -q genfstab -U /mnt
  mnt_mrcc_folder="/mnt$mrcc_folder"
  trace -q mkdir -p $mnt_mrcc_folder
  NEW_LOG_FILE=$mnt_mrcc_folder/log.txt
  log -q "$""mv $LOG_FILE $NEW_LOG_FILE"
  mv $LOG_FILE $NEW_LOG_FILE
  LOG_FILE=$NEW_LOG_FILE
  log -q "$?"
  trace -q cp $0 $mnt_mrcc_folder/mrcc-install.sh
  ls ~/.*_history &>/dev/null && trace -q mv ~/.*_history $mnt_mrcc_folder
  log -q "$""arch-chroot /mnt $mrcc_folder/mrcc-install.sh install ${args[@]} -a $archdisk"
  arch-chroot /mnt $mrcc_folder/mrcc-install.sh install "${args[@]}" -a "$archdisk"
  log -q "$?"
  [ -e .bash_profile ] trace -q cp /mnt/root/.bash_profile /mnt/root/.bash_profile_old
  file="/mnt/root/.bash_profile"
  trace-file -q echo "$mrcc_folder/mrcc-install.sh post-install ${args[@]}"
  trace -q chmod +x /mnt/root/.bash_profile
  eval "$finally"
}

[ "$state" = "install" ] && {
  init2
  LOG_FILE="$mrcc_folder/log.txt"
  trace -q ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
  trace -q hwclock --systohc
  trace -q timedatectl status
  file="/etc/locale.gen"
  trace-file -q echo "en_US.UTF-8 UTF-8  "
  trace-file -q echo "pl_PL.UTF-8 UTF-8  "
  trace -q locale-gen
  file="/etc/locale.conf"
  trace-file -q echo "LANG=pl_PL.UTF-8"
  trace-file -q echo "LANGUAGE=pl_PL"
  file="/etc/vconsole.conf"
  trace-file -q echo "KEYMAP=pl"
  trace-file -q echo "FONT=lat2-16.psfu.gz"
  trace-file -q echo "FONT_MAP=8859-2"
  file="/etc/hostname"
  trace-file -q echo "$compname"
  file="/etc/hosts"
  trace-file -q echo -e "127.0.0.1\tlocalhost"
  trace-file -q echo -e "::1\t\tlocalhost"
  trace-file -q echo -e "127.0.1.1\t$compname.localdomain\t$compname"
  "$interactive_mode" && trace passwd
  trace -q bootctl install
  file="/boot/loader/loader.conf"
  trace-file -q echo "default arch"
  trace-file -q echo "timeout 5"
  file="/boot/loader/entries/arch.conf"
  trace-file -q echo "title Arch Linux ($compname)"
  trace-file -q echo "linux /vmlinuz-linux"
  trace-file -q echo "initrd /intel-ucode.img"
  trace-file -q echo "initrd /initramfs-linux.img"
  trace-file -q echo "initrd /initramfs-linux-fallback.img"
  trace-file -q echo "options root=`blkid -o export $archdisk | grep PARTUUID 2>> $LOG_FILE` rw"
  trace -q pacman -S intel-ucode --noconfirm
}

[ "$state" = "post-install" ] && {
  init2
  LOG_FILE="$mrcc_folder/log.txt"
  trace rm /root/.bash_profile
  [ -e /root/.bash_profile_old ] && trace mv /root/.bash_profile_old /root/.bash_profile
  log "Hello world!"
  "$mrcc_remove" && rm -rf "$mrcc_folder"
}
exit 0
