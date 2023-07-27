#!/bin/bash

#  ███████ ██ ██████  ███████ ███████  ██████  ██   ██ 
#  ██      ██ ██   ██ ██      ██      ██    ██  ██ ██  
#  █████   ██ ██████  █████   █████   ██    ██   ███   
#  ██      ██ ██   ██ ██      ██      ██    ██  ██ ██  
#  ██      ██ ██   ██ ███████ ██       ██████  ██   ██ 

set -euo pipefail
IFS=$'\n\t'

grep --quiet 'MOZ_ENABLE_WAYLAND=1' /etc/environment || sudo tee --append /etc/environment <<- 'EOF'
MOZ_ENABLE_WAYLAND=1'
EOF
grep --quiet 'MOZ_DBUS_REMOTE=1' /etc/environment || sudo tee --append /etc/environment <<- 'EOF'
MOZ_DBUS_REMOTE=1'
EOF
