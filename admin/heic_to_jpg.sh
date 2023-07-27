#!/bin/bash

# ██   ██ ███████ ██  ██████     ████████  ██████           ██ ██████  ███████  ██████  
# ██   ██ ██      ██ ██             ██    ██    ██          ██ ██   ██ ██      ██       
# ███████ █████   ██ ██             ██    ██    ██          ██ ██████  █████   ██   ███ 
# ██   ██ ██      ██ ██             ██    ██    ██     ██   ██ ██      ██      ██    ██ 
# ██   ██ ███████ ██  ██████        ██     ██████       █████  ██      ███████  ██████  

# Convert heic & HEIC to jpg. With cleainig.

set -euo pipefail
IFS=$'\n\t'

# Rename *.heic of 'image/jpeg' to *.jpg
find . -type f -iname '*.heic' -print0 \
  | xargs -0I@ file --mime-type '@' \
  | grep --null 'image/jpeg' \
  | sed 's/:.*$//' \
  | xargs -I@ sh -c 'mv "${1}" "${1%.*}.jpg"' sh @ \;

# Convert *.heic of 'image/heic' to *.jpg, then delete *.heic
find . -type f -iname '*.heic' -print0 \
  | xargs -0I@ file --mime-type '@' \
  | grep --null 'image/heic' \
  | sed 's/:.*$//' \
  | xargs -I@ sh -c 'heif-convert "${1}" "${1%.*}.jpg" && rm "${1}"' sh @ \;
