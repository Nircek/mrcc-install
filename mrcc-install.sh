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
  while [ true ]
  do
    read -rsn1 key
    if [ $key = 'y' ] || [ $key = 'Y' ]
    then
      return 0
    elif [ $key = 'n' ] || [ $key = 'N' ]
    then
      return 1
    fi
  done
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
}

text="mrcc-install
Copyright (c) 2019 Nircek
under MIT License

There is NO WARRANTY, to the extent permitted by law.
I'm not taking any responsibility for anything that this program does.
Please use it with caution.
Do you accept this?
"
echo -e "$text"
choice
[ $? -eq 1 ] && exit 1
log "Started logging"
[ -d /sys/firmware/efi ] || { log "This is not EFI. Sorry."; exit 2; }
trace echo xd
