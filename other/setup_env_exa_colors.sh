#!/bin/bash

#  ███████ ██   ██  █████       ██████  ██████  ██       ██████  ██████  ███████
#  ██       ██ ██  ██   ██     ██      ██    ██ ██      ██    ██ ██   ██ ██
#  █████     ███   ███████     ██      ██    ██ ██      ██    ██ ██████  ███████
#  ██       ██ ██  ██   ██     ██      ██    ██ ██      ██    ██ ██   ██      ██
#  ███████ ██   ██ ██   ██      ██████  ██████  ███████  ██████  ██   ██ ███████

# Adds EXA_COLOR environment variable

set -euo pipefail
IFS=$'\n\t'

grep --quiet 'EXA_COLORS=' ~/.bashrc || tee --append ~/.bashrc <<- 'EOF'

# https://the.exa.website/
export EXA_COLORS="da=38;5;12:gm=38;5;12:di=38;5;12;01:xx=36"
EOF
