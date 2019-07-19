#!/usr/bin/env bash
# file from https://gist.github.com/Nircek/
# licensed under MIT license

# MIT License

# Copyright (c) 2019 Nircek

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the \"Software\"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
choice () {
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
  [ $? -eq 0 ] && return 1 || return 0
}

LOG_FILE=log.txt

timed () {
  echo "`date +"[%Y-%m-%d %H:%M:%S]"`> $@"
}

log () {
  timed "$@" | tee -a $LOG_FILE
}

trace () {
  log "$""$@"
  "$@" 2>&1 | tee -a $LOG_FILE
  r=${PIPESTATUS[0]}${pipestatus[1]}
  log "$r"
  return $r
}

trace-file () {
  # argument: $file
  log "$""$@ >> $file"
  "$@" >> "$file" 2>&1 | tee -a $LOG_FILE
  r=${PIPESTATUS[0]}${pipestatus[1]}
  log "$r"
  return $r
}

internet () {
  ping 8.8.8.8 -c1 > /dev/null
}
text="mrcc-install
Copyright (c) 2019 Nircek
under MIT License

There is NO WARRANTY, to the extent permitted by law.
I'm not taking any responsibility for anything that this program does.
Please use it with caution.
"

init2 () {
  exit () {
    log "Exit with code: $@"
    command exit "$@"
  }
}

[ "$1" != "install" ] && [ "$1" != "post-install" ] && {
  echo -e "$text"
  choice-no "Do you accept this?" && exit 1
  log "Started logging"
  init2
  [ -d /sys/firmware/efi ] || { log "This is not EFI. Sorry."; exit 2; }
  good="is"
  bad () { good="is NOT"; "$@"; }
  archiso="`find /dev/disk/by-label/ARCH_*  -printf "%f\n" 2>/dev/null`" || { bad; archiso="UNKNOWN"; }
  pacman="`pacman -Q linux 2>/dev/null`" || { bad; linux="NO PACMAN"; }
  [ "`uname -s`" = "Linux" ] && [ "`uname -o`" = "GNU/Linux" ] && linux="`uname -sr`" || { bad; linux="NO LINUX"; }
  name="`uname -n`"
  [ "$name" = "archiso" ] || bad
  log "Your version of system is $archiso."
  log "Found $linux by uname and $pacman by pacman."
  log "The nodename is $name."
  log "I think it $good an iso of Arch Linux."
  [ "$good" != "is" ] && choice-no "Do you REALLY want to continue?" && exit 3
  trace loadkeys pl
  trace setfont lat2-16.psfu.gz -m 8859-2
  internet && trace timedatectl set-ntp true && sleep 5
  trace timedatectl status
  trace fdisk -l
  while true
  do
    echo "Make 3 partitions: EFI (EF00), EXT4 and SWAP."
    read -p"Type the name of your device (or ':' to go next): " disk
    [ "$disk" = ":" ] && break
    trace gdisk $disk
    fdisk -l
  done
  read -p"Type the name of your EFI partition: " efidisk
  choice "Do you want to format it?" && trace mkfs.vfat $efidisk
  while true
  do
    read -p"Type the name of your EXT4 partition: " archdisk
    choice "I will format it." && trace mkfs.ext4 $archdisk && break
  done
  read -p"Type the name of your SWAP partition: " swapdisk
  choice "Do you want to format it?" && trace mkswap $swapdisk
  trace swapon $swapdisk
  trace mount $archdisk /mnt
  trace mkdir /mnt/boot
  trace mount $efidisk /mnt/boot
  choice "Do you want to install Wi-Fi stuff?" && adds="wpa_supplicant dialog" || adds=""
  trace pacstrap /mnt base $adds
  file="/mnt/etc/fstab"
  trace-file genfstab -U /mnt
  CH_PRE_FOLDER="/root/.mrcc/pre" #CHroot
  PRE_FOLDER="/mnt$CH_PRE_FOLDER"
  trace mkdir -p $PRE_FOLDER
  NEW_LOG_FILE=$PRE_FOLDER/log.txt
  log "$""mv $LOG_FILE $NEW_LOG_FILE"
  mv $LOG_FILE $NEW_LOG_FILE
  LOG_FILE=$PRE_FOLDER/log.txt
  log "$?"
  trace cp $0 $PRE_FOLDER/mrcc-install.sh
  ls ~/.*_history &>/dev/null && trace mv ~/.*_history $PRE_FOLDER
  log "$""chroot /mnt $CH_PRE_FOLDER/mrcc-install.sh install $archdisk"
  arch-chroot /mnt $CH_PRE_FOLDER/mrcc-install.sh install $archdisk
  log "$?"
  [ -e .bash_profile ] trace cp /mnt/root/.bash_profile /mnt/root/.bash_profile_old
  file="/mnt/root/.bash_profile"
  trace-file echo "/root/.mrcc/pre/mrcc-install.sh post-install"
  trace chmod +x /mnt/root/.bash_profile
  shutdown now
}

[ "$1" = "install" ] && {
  init2
  LOG_FILE="/root/.mrcc/pre/log.txt"
  trace ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
  trace hwclock --systohc
  trace timedatectl status
  file="/etc/locale.gen"
  trace-file echo "en_US.UTF-8 UTF-8  "
  trace-file echo "pl_PL.UTF-8 UTF-8  "
  trace locale-gen
  file="/etc/locale.conf"
  trace-file echo "LANG=pl_PL.UTF-8"
  trace-file echo "LANGUAGE=pl_PL"
  file="/etc/vconsole.conf"
  trace-file echo "KEYMAP=pl"
  trace-file echo "FONT=lat2-16.psfu.gz"
  trace-file echo "FONT_MAP=8859-2"
  name="ARCH-MRCC-`date +"%-d%-m%y"`"
  file="/etc/hostname"
  trace-file echo "$name"
  file=/etc/hosts
  trace-file echo -e "127.0.0.1\tlocalhost"
  trace-file echo -e "::1\t\tlocalhost"
  trace-file echo -e "127.0.1.1\t$name.localdomain\t$name"
  trace passwd
  trace bootctl install
  file="/boot/loader/loader.conf"
  trace-file echo "default arch"
  trace-file echo "timeout 5"
  file="/boot/loader/entries/arch.conf"
  trace-file echo "title Arch Linux ($name)"
  trace-file echo "linux /vmlinuz-linux"
  trace-file echo "initrd /intel-ucode.img"
  trace-file echo "initrd /initramfs-linux.img"
  trace-file echo "initrd /initramfs-linux-fallback.img"
  trace-file echo "options root=`blkid -o export $2 | grep PARTUUID 2>> $LOG_FILE` rw"
  trace pacman -S intel-ucode --noconfirm
}

[ "$1" = "post-install" ] && {
  init2
  LOG_FILE="/root/.mrcc/pre/log.txt"
  trace rm /root/.bash_profile
  [ -e /root/.bash_profile_old ] && trace mv /root/.bash_profile_old /root/.bash_profile
  log "Hello world!"
}
exit 0
