#!/bin/bash

#  ██████   █████  ███████ ██   ██      █████  ██      ██  █████  ███████ ███████ ███████
#  ██   ██ ██   ██ ██      ██   ██     ██   ██ ██      ██ ██   ██ ██      ██      ██
#  ██████  ███████ ███████ ███████     ███████ ██      ██ ███████ ███████ █████   ███████
#  ██   ██ ██   ██      ██ ██   ██     ██   ██ ██      ██ ██   ██      ██ ██           ██
#  ██████  ██   ██ ███████ ██   ██     ██   ██ ███████ ██ ██   ██ ███████ ███████ ███████

# Adds couple commandline bash shortcuts.

set -euo pipefail
IFS=$'\n\t'

grep --quiet 'alias clip=' ~/.bash_aliases || tee --append ~/.bash_aliases <<- 'EOF'
alias clip='xclip -r -sel clip'
EOF
grep --quiet 'alias exa=' ~/.bash_aliases || tee --append ~/.bash_aliases <<- 'EOF'
alias exa='exa --header --git --all --long --classify --no-user --time-style long-iso'
EOF
grep --quiet 'alias gitas=' ~/.bash_aliases || tee --append ~/.bash_aliases <<- 'EOF'
alias gitas='gita ll -h'
EOF
grep --quiet 'alias gacp=' ~/.bash_aliases || tee --append ~/.bash_aliases <<- 'EOF'
alias gacp='git add -u ; git commit -m "chore: update" ; git push'
EOF