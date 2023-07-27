#!/bin/bash

#  ██ ███    ██ ███████ ████████  █████  ██      ██           ██████  ███    ██ ██████  ███████ ██████  ██ ██    ██ ███████ 
#  ██ ████   ██ ██         ██    ██   ██ ██      ██          ██    ██ ████   ██ ██   ██ ██      ██   ██ ██ ██    ██ ██      
#  ██ ██ ██  ██ ███████    ██    ███████ ██      ██          ██    ██ ██ ██  ██ ██   ██ █████   ██████  ██ ██    ██ █████   
#  ██ ██  ██ ██      ██    ██    ██   ██ ██      ██          ██    ██ ██  ██ ██ ██   ██ ██      ██   ██ ██  ██  ██  ██      
#  ██ ██   ████ ███████    ██    ██   ██ ███████ ███████      ██████  ██   ████ ██████  ███████ ██   ██ ██   ████   ███████ 

# Performs Onedrive installation.

# Check (https://github.com/abraunegg/onedrive/blob/master/docs/USAGE.md) guide.

set -euo pipefail
IFS=$'\n\t'

rm --recursive --force /var/lib/dpkg/lock-frontend
rm --recursive --force /var/lib/dpkg/lock
apt-get update
apt-get upgrade --assume-yes
apt-get dist-upgrade --assume-yes
apt-get autoremove --assume-yes
apt-get autoclean --assume-yes

wget -qO - https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_22.10/Release.key | gpg --dearmor | sudo tee /usr/share/keyrings/obs-onedrive.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_22.10/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list
sudo apt update
sudo apt install --no-install-recommends --no-install-suggests onedrive
