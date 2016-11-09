#!/usr/bin/env bash
ARGS=$@

yum install -y sudo git
sed -i.bak \
  -e 's/\(^%wheel\s*ALL=(ALL)\s*ALL\)/# \1/' \
  -e 's/^#\s\(%wheel\s*ALL=(ALL)\s*NOPASSWD:\s*ALL\)/\1/' \
  /etc/sudoers
useradd -m -G wheel travis
# Docker issue #2259
chown -R travis:travis ~travis
sudo -E -u travis ./X11RDP-RH-Matic.sh ${ARGS}
