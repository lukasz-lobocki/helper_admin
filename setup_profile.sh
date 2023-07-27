#!/bin/bash

# ███████ ███████ ████████ ██    ██ ██████      ██████  ██████   ██████  ███████ ██ ██      ███████
# ██      ██         ██    ██    ██ ██   ██     ██   ██ ██   ██ ██    ██ ██      ██ ██      ██
# ███████ █████      ██    ██    ██ ██████      ██████  ██████  ██    ██ █████   ██ ██      █████
#      ██ ██         ██    ██    ██ ██          ██      ██   ██ ██    ██ ██      ██ ██      ██
# ███████ ███████    ██     ██████  ██          ██      ██   ██  ██████  ██      ██ ███████ ███████

# Adds `~\helper` to search path.

set -euo pipefail
IFS=$'\n\t'

grep --quiet '$HOME/helper' ~/.profile || tee --append ~/.profile <<- 'EOF'

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/helper" ] ; then
    PATH="$HOME/helper:$PATH"
fi
EOF
