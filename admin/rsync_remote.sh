#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Basic snapshot-style rsync backup script

# Config
OPTa="--stats --verbose --itemize-changes --progress"
OPTb="--archive --compress --bwlimit=2000 --partial --inplace --one-file-system --delete -e ssh"
SRC=/mnt/btrfs/ncdata/data/lukasz/files
DST=la_lukasz@lobocki.ddns.net:base/ster_nextcloud

# Run rsync to create snapshot
rsync "${OPTa}" "${OPTb}" "${SRC}" "{$DST}"


# la_lukasz@nextcloudpi:~$ rsync --archive --stats --verbose --compress --bwlimit=2000 --partial --inplace --one-file-system --itemize-changes --progress ####--dry-run### --delete -e ssh /mnt/btrfs/ncdata/data/lukasz/files la_lukasz@lobocki.ddns.net:base/ster_nextcloud
