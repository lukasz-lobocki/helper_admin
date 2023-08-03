#!/bin/bash

#  ██████   ██████  ██████   ██████          ██████   █████  ███████ ███████  ██████  ██████  ███    ███ ███    ███  █████  ███    ██ ██████
#  ██   ██ ██    ██ ██   ██ ██               ██   ██ ██   ██ ██      ██      ██      ██    ██ ████  ████ ████  ████ ██   ██ ████   ██ ██   ██
#  ██████  ██    ██ ██████  ██   ███         ██████  ███████ ███████ ███████ ██      ██    ██ ██ ████ ██ ██ ████ ██ ███████ ██ ██  ██ ██   ██
#  ██   ██ ██    ██ ██   ██ ██    ██         ██      ██   ██      ██      ██ ██      ██    ██ ██  ██  ██ ██  ██  ██ ██   ██ ██  ██ ██ ██   ██
#  ██████   ██████  ██   ██  ██████  ███████ ██      ██   ██ ███████ ███████  ██████  ██████  ██      ██ ██      ██ ██   ██ ██   ████ ██████

# Adds BORG_PASSCOMMAND environment variable

set -euo pipefail
IFS=$'\n\t'

grep --quiet 'BORG_PASSCOMMAND=' ~/.bashrc || tee --append ~/.bashrc <<- 'EOF'

# https://borgbackup.readthedocs.io/en/stable/faq.html?highlight=BORG_PASSCOMMAND#how-can-i-specify-the-encryption-passphrase-programmatically
# https://borgbackup.readthedocs.io/en/stable/usage/key.html
export BORG_PASSCOMMAND="cat $HOME/.borg-passphrase"
EOF
