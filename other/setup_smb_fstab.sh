#!/bin/bash

# ███████  █████  ███    ███ ██████   █████      ███████ ███████ ████████  █████  ██████
# ██      ██   ██ ████  ████ ██   ██ ██   ██     ██      ██         ██    ██   ██ ██   ██
# ███████ ███████ ██ ████ ██ ██████  ███████     █████   ███████    ██    ███████ ██████
#      ██ ██   ██ ██  ██  ██ ██   ██ ██   ██     ██           ██    ██    ██   ██ ██   ██
# ███████ ██   ██ ██      ██ ██████  ██   ██     ██      ███████    ██    ██   ██ ██████

# Creates fstab entries for automounting particuar drives.

set -euo pipefail
IFS=$'\n\t'

sudo mkdir /media/smb/lukasz
sudo chmod 777 /media/smb/lukasz
sudo mkdir /media/smb/public
sudo chmod 777 /media/smb/public
sudo mkdir /media/smb/home
sudo chmod 777 /media/smb/home
sudo mkdir /media/smb/base
sudo chmod 777 /media/smb/base

grep --quiet '/media/smb/lukasz cifs' /etc/fstab || sudo tee --append /etc/fstab <<- 'EOF'
//192.168.2.1/lukasz /media/smb/lukasz cifs credentials=/home/lukasz/.smb_cred_ster,iocharset=utf8,vers=1.0,dir_mode=0777,file_mode=0777,nounix 0 0
EOF

grep --quiet '/media/smb/public cifs' /etc/fstab || sudo tee --append /etc/fstab <<- 'EOF'
//192.168.2.1/public /media/smb/public cifs credentials=/home/lukasz/.smb_cred_ster,iocharset=utf8,vers=1.0,dir_mode=0777,file_mode=0777,nounix 0 0
EOF

grep --quiet '/media/smb/home cifs' /etc/fstab || sudo tee --append /etc/fstab <<- 'EOF'
//192.168.2.1/home /media/smb/home cifs credentials=/home/lukasz/.smb_cred_ster,iocharset=utf8,vers=1.0,dir_mode=0777,file_mode=0777,nounix 0 0
EOF

grep --quiet '/media/smb/base cifs' /etc/fstab || sudo tee --append /etc/fstab <<- 'EOF'
//lobocki.ddns.net/base /media/smb/base cifs credentials=/home/lukasz/.smb_cred_slon,iocharset=utf8,vers=3,dir_mode=0777,file_mode=0777,nounix 0 0
EOF

echo -e "user=lukasz \
  password=********" | tee --append ~/.smb_cred_ster

echo -e "user=lukasz \
  password=********" | tee --append ~/.smb_cred_slon

sudo apt install cifs-utils
sudo mount --all
systemctl daemon-reload
