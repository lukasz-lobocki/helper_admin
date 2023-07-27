#!/bin/bash

# ███████ ███████ ████████ ██    ██ ██████      ██    ██ ███████ ██████      ██    ██ ██████  ███████ ██    ██ ███████
# ██      ██         ██    ██    ██ ██   ██     ██    ██ ██      ██   ██     ██    ██ ██   ██ ██      ██    ██ ██
# ███████ █████      ██    ██    ██ ██████      ██    ██ ███████ ██████      ██    ██ ██   ██ █████   ██    ██ ███████
#      ██ ██         ██    ██    ██ ██          ██    ██      ██ ██   ██     ██    ██ ██   ██ ██       ██  ██       ██
# ███████ ███████    ██     ██████  ██           ██████  ███████ ██████       ██████  ██████  ███████   ████   ███████

# Creates unique usb aliases for my different microcontroller boards.

set -euo pipefail
IFS=$'\n\t'

# Interrogate
# udevadm info --name=/dev/ttyACM0
# TTYDEVICE="ttyACM0" ; sudo echo -e "$(udevadm info -a -n /dev/${TTYDEVICE} | grep ATTRS{idVendor}) \n$(udevadm info -a -n /dev/${TTYDEVICE} | grep ATTRS{idProduct}) \n$(udevadm info -a -n /dev/${TTYDEVICE} | grep ATTRS{serial}) \n"

grep --quiet 'ESP32_S3_mini' /etc/udev/rules.d/99-usb-serial.rules || sudo tee --append /etc/udev/rules.d/99-usb-serial.rules <<- 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="4001", ATTRS{serial}=="123456", SYMLINK+="ESP32_S3_mini"
EOF

grep --quiet 'ESP32_S3_pro' /etc/udev/rules.d/99-usb-serial.rules || sudo tee --append /etc/udev/rules.d/99-usb-serial.rules <<- 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="80d4", ATTRS{serial}=="_ps3_", SYMLINK+="ESP32_S3_pro"
EOF

grep --quiet 'ESP32_C3' /etc/udev/rules.d/99-usb-serial.rules || sudo tee --append /etc/udev/rules.d/99-usb-serial.rules <<- 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", ATTRS{serial}=="34:85:18:03:11:E0", SYMLINK+="ESP32_C3"
EOF

grep --quiet 'nRF52840' /etc/udev/rules.d/99-usb-serial.rules || sudo tee --append /etc/udev/rules.d/99-usb-serial.rules <<- 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="f055", ATTRS{idProduct}=="9802", ATTRS{serial}=="000000000000", SYMLINK+="nRF52840"
EOF

grep --quiet 'RP2040' /etc/udev/rules.d/99-usb-serial.rules || sudo tee --append /etc/udev/rules.d/99-usb-serial.rules <<- 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0005", ATTRS{serial}=="e661640843307526", SYMLINK+="RP2040"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger
