#!/bin/bash

#  ███████ ██ ██████  ███████ ███████  ██████  ██   ██ 
#  ██      ██ ██   ██ ██      ██      ██    ██  ██ ██  
#  █████   ██ ██████  █████   █████   ██    ██   ███   
#  ██      ██ ██   ██ ██      ██      ██    ██  ██ ██  
#  ██      ██ ██   ██ ███████ ██       ██████  ██   ██ 

set -euo pipefail
IFS=$'\n\t'

sudo snap remove firefox
sudo add-apt-repository ppa:mozillateam/ppa

echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox

sudo apt install firefox

grep --quiet 'MOZ_ENABLE_WAYLAND=1' /etc/environment || sudo tee --append /etc/environment <<- 'EOF'
MOZ_ENABLE_WAYLAND=1'
EOF
grep --quiet 'MOZ_DBUS_REMOTE=1' /etc/environment || sudo tee --append /etc/environment <<- 'EOF'
MOZ_DBUS_REMOTE=1'
EOF
