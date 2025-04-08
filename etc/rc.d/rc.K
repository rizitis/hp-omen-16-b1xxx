#!/bin/bash
#
# rc.K 		This file is executed by init when it goes into runlevel
#		1, which is the administrative state. It kills all
#		daemons and then puts the system into single user mode.
#		Note that the file systems are kept mounted.
#
# Version:	@(#)/etc/rc.d/rc.K	3.1415 Sat Jan 13 13:37:26 PST 2001
#
# Author:	Miquel van Smoorenburg <miquels@drinkel.nl.mugnet.org>
# Modified by:  Patrick J. Volkerding <volkerdi@slackware.com>
#

# Set the path.
PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin

# Load a custom screen font if the user has an rc.font script.
if [ -x /etc/rc.d/rc.font ]; then
  /etc/rc.d/rc.font
fi

# Load any needed keyboard mappings:
if [ -x /etc/rc.d/rc.keymap ]; then
  /etc/rc.d/rc.keymap
fi

# If there are SystemV init scripts for this runlevel, run them.
if [ -x /etc/rc.d/rc.sysvinit ]; then
  /etc/rc.d/rc.sysvinit
fi

# Try to turn off quota:
if grep -q quota /etc/fstab ; then
  if [ -x /sbin/quotaoff ]; then
    echo "Turning off filesystem quotas."
    /sbin/quotaoff -a
  fi
fi

# Try to turn off accounting:
if [ -x /sbin/accton -a -r /var/log/pacct ]; then
  /sbin/accton off
fi

# Run any local shutdown scripts:
if [ -x /etc/rc.d/rc.local_shutdown ]; then
  /etc/rc.d/rc.local_shutdown stop
fi

# Stop network services (Apache, Samba, NFS, etc.)
for service in httpd samba nfsd pcscd acpid pcmcia; do
  if [ -x /etc/rc.d/rc.$service ]; then
    /etc/rc.d/rc.$service stop
  fi
done

# Kill any processes (typically gam) that would otherwise prevent
# unmounting NFS volumes:
unset FUSER_DELAY
for dir in $(/bin/mount | grep -e 'type nfs ' -e 'type nfs4 ' | sed -e 's|.* on ||g' | cut -d ' ' -f 1) ; do
  echo "Killing processes holding NFS mount $dir open..."
  # Background this to prevent fuser from also blocking shutdown:
  /usr/bin/fuser -k -M -m "$dir" &
  FUSER_DELAY=5
done
# If fuser was run, let it have some delay:
if [ ! -z "$FUSER_DELAY" ]; then
  sleep $FUSER_DELAY
fi

# Unmount any NFS, SMB, or CIFS filesystems:
echo "Unmounting remote filesystems:"
for fs in $(/bin/mount | grep -e 'type nfs ' -e 'type nfs4 ' -e 'type smbfs ' -e 'type cifs ' | sed -e 's|.* on ||g' | cut -d ' ' -f 1); do
  /bin/umount -v -l -f -r "$fs"
  if [ $? -eq 0 ]; then
    echo "$fs has been successfully unmounted."
  else
    echo "Failed to unmount $fs."
  fi
done

# Ensure safe disk sync before unmounting
echo "Syncing filesystem buffers..."
sync
sync
sync

# Unmount all local filesystems for safer shutdown
echo "Unmounting all local filesystems..."
/bin/umount -a -r

# Remount root as read-only to prevent corruption
echo "Remounting root filesystem as read-only..."
mount -o remount,ro /

# Kill all processes.
OMITPIDS="$(for p in $(pgrep mdmon); do echo -o $p; done)"
echo "Sending all processes the SIGHUP signal."
killall5 -1 $OMITPIDS
sleep 5
echo "Sending all processes the SIGTERM signal."
killall5 -15 $OMITPIDS
sleep 5
echo "Sending all processes the SIGKILL signal."
killall5 -9 $OMITPIDS
sleep 5

echo "Shutdown cleanup complete. Going to single user mode..."
/sbin/telinit -t 1 1
