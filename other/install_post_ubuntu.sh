#!/bin/bash

#  ██    ██ ██████  ██    ██ ███    ██ ████████ ██    ██     ██████   ██████  ███████ ████████       ██ ███    ██ ███████ ████████  █████  ██      ██      
#  ██    ██ ██   ██ ██    ██ ████   ██    ██    ██    ██     ██   ██ ██    ██ ██         ██          ██ ████   ██ ██         ██    ██   ██ ██      ██      
#  ██    ██ ██████  ██    ██ ██ ██  ██    ██    ██    ██     ██████  ██    ██ ███████    ██    █████ ██ ██ ██  ██ ███████    ██    ███████ ██      ██      
#  ██    ██ ██   ██ ██    ██ ██  ██ ██    ██    ██    ██     ██      ██    ██      ██    ██          ██ ██  ██ ██      ██    ██    ██   ██ ██      ██      
#   ██████  ██████   ██████  ██   ████    ██     ██████      ██       ██████  ███████    ██          ██ ██   ████ ███████    ██    ██   ██ ███████ ███████ 

set -euo pipefail
IFS=$'\n\t'

sudo apt update && sudo apt upgrade

# Gnome add-ons

sudo apt install gnome-tweaks
sudo apt install gnome-shell-extensions
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews'
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false

# Python
echo 'new approach: try to use venv & pip - for PYTHON modules'
echo 'python3 -m venv homenv'
echo 'source ~/homenv/bin/activate'

exit 0

sudo apt install python3-pip
sudo apt install thonny
sudo usermod --append --groups dialout "${USER}"

# Other

sudo apt install xclip

sudo add-apt-repository ppa:phoerious/keepassxc; sudo apt update
sudo apt install keepassxc

sudo apt-add-repository ppa:fish-shell/release-3; sudo apt update
sudo apt install fish

sudo add-apt-repository ppa:alexx2000/doublecmd; sudo apt update
sudo apt install doublecmd-gtk

sudo apt install xxhash
sudo apt install cookiecutter
sudo apt install nodejs
sudo apt install ttf-mscorefonts-installer
sudo apt install p7zip
sudo apt install network-manager-l2tp network-manager-l2tp-gnome
sudo apt install wireguard
sudo apt install borgbackup
echo "https://forum.openmediavault.org/index.php?thread/44252-how-to-use-the-openmediavault-wireguard-plugin/"

# Git

sudo add-apt-repository ppa:git-core/ppa; sudo apt update
sudo apt install git
sudo apt install gh
sudo apt install gitg
sudo apt install gita
gh auth login

# Poetry

echo 'source ~/homenv/bin/activate'
# pip install poetry
#sudo apt install python3-poetry
#poetry config virtualenvs.options.no-pip true
#poetry config virtualenvs.options.no-setuptools true
#poetry config virtualenvs.in-project true

# Housekeeping

sudo apt update && sudo apt upgrade \
  && sudo apt autoclean && sudo apt clean && sudo apt autoremove
