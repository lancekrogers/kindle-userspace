#!/bin/sh
# Name: Start SSH
# Author: kindle-userspace
# Wi-Fi dropbear only. Does not enable USB ethernet gadget.
#
# Install: copy to /mnt/us/documents/Start-SSH.sh and /mnt/us/bin/start-ssh
# After every reboot, tap the book or run this from kTerm.
#
# First login (password still on): ALLOW_PASSWORD=true ./start-ssh.sh
# After your key is in /mnt/us/.ssh/authorized_keys: default is key-only.

LOG=/mnt/us/ssh_start.log
BIN=/mnt/us/usbnetlite/bin
ETC=/mnt/us/usbnetlite/etc/dropbear
DB="$BIN/dropbearmulti"
ALLOW_PASSWORD="${ALLOW_PASSWORD:-false}"

echo "=== Start SSH ===" >"$LOG"
echo "=== Start SSH ==="

if [ ! -f "$DB" ]; then
  echo "MISSING $DB — stage USBNetLite under /mnt/us/usbnetlite first" | tee -a "$LOG"
  exit 1
fi

mkdir -p "$ETC" /mnt/us/.ssh
if [ -f "$ETC/authorized_keys" ]; then
  cp -f "$ETC/authorized_keys" /mnt/us/.ssh/authorized_keys
fi

killall dropbear 2>/dev/null
killall dropbearmulti 2>/dev/null
sleep 1

# -R host keys  -H home=/mnt/us  so authorized_keys is /mnt/us/.ssh/authorized_keys
opts="-R -H /mnt/us -p 22 -K 15"
if [ "$ALLOW_PASSWORD" = "true" ]; then
  opts="$opts -Y kindle"
else
  opts="$opts -s"
fi

# word-split opts on purpose
# shellcheck disable=SC2086
"$DB" dropbear $opts >>"$LOG" 2>&1
echo "dropbear exit=$?" | tee -a "$LOG"

iptables -I INPUT -i wlan0 -p tcp --dport 22 -j ACCEPT >>"$LOG" 2>&1 || true

echo "DONE. Stay on Wi-Fi. Do not plug USB." | tee -a "$LOG"
exit 0
