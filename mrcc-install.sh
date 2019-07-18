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
  return ${PIPESTATUS[0]}${pipestatus[1]}
}

text="mrcc-install
Copyright (c) 2019 Nircek
under MIT License

There is NO WARRANTY, to the extent permitted by law.
I'm not taking any responsibility for anything that this program does.
Please use it with caution.
"
echo -e "$text"
choice-no "Do you accept this?" && exit 1
log "Started logging"
exit () {
  log "Exit with code: $@"
  command exit "$@"
}
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
[ "$good" != "is" ] && trace choice-no "Do you REALLY want to continue?" && exit 3
exit 0
