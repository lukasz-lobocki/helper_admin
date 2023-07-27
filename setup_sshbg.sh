#!/bin/bash

# ███████ ███████ ██   ██ ██████   ██████  
# ██      ██      ██   ██ ██   ██ ██       
# ███████ ███████ ███████ ██████  ██   ███ 
#      ██      ██ ██   ██ ██   ██ ██    ██ 
# ███████ ███████ ██   ██ ██████   ██████  
                                         
set -euo pipefail
IFS=$'\n\t'

cat <<- "EOF" | tee ~/.config/sshbg.conf
{
    "normal_bg_color": "#000000",
    "profiles": {
        "prod": "#4F0100",
        "uat": "#012F00",
        "test": "#011A00"
    },
    "hostnames": {
        "192.168.2.144": "prod"
    }
}
EOF
