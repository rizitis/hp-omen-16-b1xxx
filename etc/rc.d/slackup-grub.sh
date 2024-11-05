#!/bin/bash

# Anagnostakis Ioannis GR Crete 26/03/2023
# Update Grub when Slackware upgrade-all upgrade kernel release...
# and me/you forgot to update-grub...
# In my case I use SBKS and always have a backup kernel in my system. (https://github.com/rizitis/SBKS) #
# But just in case....

# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# root
if [ "$EUID" -ne 0 ];then
echo "ROOT ACCESS PLEASE OR GO HOME..."
exit 1
fi

# if first time run mk slackup-grub dir
dir=/usr/local/slackup-grub
file=/usr/local/slackup-grub/slackup-grub.TXT
file2=/usr/local/slackup-grub/slackup-grub.BAK
dirgg=/usr/local/slackgrub-install
filegg=/usr/local/slackgrub-install/slackgrub-install.TXT
filegg2=/usr/local/slackgrub-install/slackgrub-install.BAK


if [ -d "$dir" ]
then
echo "slackup-grub is installed"
else
mkdir -p "$dir"
/bin/ls -tr /var/log/pkgtools/removed_scripts/ | grep kernel | tail -3 > "$file"
echo "Looks like you are running slackup-grub for first time?"
exit
fi

cd "$dirgg" || exit
if [ -f /usr/local/slackgrub-install/slackgrub-install.TXT ]
then 
mv "$filegg" "$filegg2" || exit
else 
echo "************************************"
echo "Something went wrong, grub-install ATTENSION... *"
echo "************************************"
exit 3
fi

if [ -f "$filegg2" ]
then 
ls /var/adm/packages/ | grep ^grub > "$filegg"
fi
if cmp -s slackgrub-install.TXT slackgrub-install.BAK ; then
echo "NO GRUB UPDATE WAS FOUND"
sleep 1
else
echo "GRUB WAS UPDATED, REINSTALL-UPDATING GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck #--debug
wait
grub-mkconfig -o /boot/grub/grub.cfg
fi



cd "$dir" || exit

if [ -f /usr/local/slackup-grub/slackup-grub.TXT ]
then 
mv "$file" "$file2" || exit
else 
echo "************************************"
echo "Something went wrong, ATTENSION... *"
echo "************************************"
exit
fi

set -e

if [ -f "$file2" ]
then 
/bin/ls -tr /var/log/pkgtools/removed_scripts/ | grep kernel | tail -3 > "$file"
fi

if cmp -s slackup-grub.TXT slackup-grub.BAK ; then
echo "NO KERNEL UPDATE WAS FOUND"
sleep 2
else
echo "KERNEL WAS UPDATED, UPDATING GRUB..."
 grub-mkconfig -o /boot/grub/grub.cfg
fi




