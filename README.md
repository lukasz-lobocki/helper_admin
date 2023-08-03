# ADMIN

```bash
git add --update && git commit -m "Gist update" && git push origin main
```

<details>
<summary>Linux updates.</summary>

```bash
sudo apt update \
  && sudo apt upgrade \
  && sudo apt autoclean \
  && sudo apt clean \
  && sudo apt autoremove

sudo apt --with-new-pkgs upgrade <packages-list>
```

</details>

## TABLE OF CONTENTS <!-- omit in toc -->

- [1. CHEATSHEET](#1-cheatsheet)
- [2. FILES HANDLING](#2-files-handling)
  - [2.1. Ownership](#21-ownership)
  - [2.2. Permisions](#22-permisions)
  - [2.3. Hashing](#23-hashing)
- [3. REMOTE COPYING with scp](#3-remote-copying-with-scp)
- [4. REMOTE SYNCHRONIZE with rsync](#4-remote-synchronize-with-rsync)
- [5. MOUNTING SAMBA](#5-mounting-samba)
- [6. BORG BACKUP](#6-borg-backup)
  - [6.1. Create _archive_](#61-create-archive)
  - [6.2. Get info](#62-get-info)
  - [6.3. Vorta to NextcloudPi backup](#63-vorta-to-nextcloudpi-backup)
  - [6.4. Prune](#64-prune)
- [7. NEXTCLOUDPi SETUP](#7-nextcloudpi-setup)
  - [7.1. Hardware](#71-hardware)
  - [7.2. Debian](#72-debian)
  - [7.3. Install](#73-install)

## 1. CHEATSHEET

Check [Bash scripting cheatsheet](https://devhints.io/bash) and [how-to-use-double-or-single-brackets-parentheses-curly-braces](https://stackoverflow.com/questions/2188199/how-to-use-double-or-single-brackets-parentheses-curly-braces) pages.

Check [TOC generator](https://luciopaiva.com/markdown-toc/) page.

## 2. FILES HANDLING

### 2.1. Ownership

```bash
sudo \
  chown --recursive www-data:www-data /mnt/btrfs/ncdata
```

### 2.2. Permisions

Check [nextcloud permisions](https://docs.nextcloud.com/server/13/admin_manual/maintenance/manual_upgrade.html) and [gist permisions](#permisions) pages.

#### Directories

```bash
sudo \
  find /mnt/btrfs/ncdata -type d -print0 \
  | xargs -0 sudo -u www-data \
    chmod u=rwx,g=rx,o=rx
```

#### Files

```bash
sudo \
  find /mnt/btrfs/ncdata -type f -print0 \
  | xargs -0 sudo -u www-data \
    chmod u=rw,g=r,o=r
```

### 2.3. Hashing

Check [file-append_xxhsum.sh](https://github.com/lukasz-lobocki/helper_admin/blob/main/other/append_xxhsum.sh) and [append-xxhsum](https://github.com/lukasz-lobocki/append-xxhsum.git) pages.

#### Managing placeholders for hashes

Create placeholder _.xxhsum_ files.

```bash
sudo -u www-data \
  find . -maxdepth 1 -mindepth 1 -type d -print0 \
    | xargs -0I@ bash -c \
    "sudo -u www-data touch '@.xxhsum'"
```

Find _.xxhsum_ placeholders and empty them.

```bash
sudo -u www-data \
  find ./ -type f -iname "*.xxhsum" \
    -exec truncate -s 0 {} +
```

#### Create hash file

Find _.xxhsum_ placeholders - modified prior to 30 days - and append them with missing xxhsum results.

```bash
sudo -u www-data \
  find . -mtime +30 -type f -iname "*.xxhsum" -print0 \
    | sed "s:.xxhsum::g" \
    | xargs -0I@ bash -c \
    "sudo -u www-data append-xxhsum '@'"
```

or by specifying the _DIRNAME_.

```bash
cd /mnt/btrfs/ncdata/data/lukasz/files
```

```bash
bash -c \
  'find_func() \
    { find "$1" -type f -print0 | xargs -0I@ xxhsum @; }; \
  find_func "$1" > "$1".xxhsum' \
_ "DIRNAME" \;
```

#### Check hash file

Check all _\*.xxhsum_ files.

```bash
find . -type f -iname "*.xxhsum" -execdir \
  bash -c \
    'echo "Checking ./$(realpath --no-symlinks \
      --canonicalize-missing \
      --relative-to="$1" \
      "$2")" \
    && xxhsum --check --quiet "$2"' \
  _ "$(pwd)" "{}" \;
```

<details>
<summary>Creation alternative with rhash.</summary>

```bash
rhash --sha256 --recursive \
  --output=.sha256 .
```
  
```bash
rhash --crc32 --recursive --simple \
  --output=.crc32 .
```

And check.

```bash
rhash --check --skip-ok \
  ./.sha256
```

```bash
rhash --check --skip-ok \
  ./.crc32
```

</details>

## 3. REMOTE COPYING with scp

With **C**ompression in transit and **r**ecursively.

```bash
scp -Cr ./directory/ username@to_host:./directory/
```

## 4. REMOTE SYNCHRONIZE with rsync

Re-synchronizes all files repository into _Slonecznikowa_.

```bash
ssh la_lukasz@nextcloudpi.local rsync \
  --archive \
  --stats \
  --verbose \
  --compress \
  --bwlimit=2000 \
  --partial \
  --inplace \
  --one-file-system \
  --itemize-changes \
  --progress \
  --delete \
  -e ssh \
  /mnt/btrfs/ncdata/data/lukasz/files \
  la_lukasz@lobocki.ddns.net:base/ster_nextcloud
```

<details>
<summary>...with dry run.</summary>

```bash
rsync \
  --archive \
  --stats \
  --verbose \
  --compress \
  --bwlimit=2000 \
  --partial \
  --inplace \
  --one-file-system \
  --itemize-changes \
  --progress \
  --dry-run \
  --delete \
  -e ssh \
  /mnt/btrfs/ncdata/data/lukasz/files \
  la_lukasz@lobocki.ddns.net:base/ster_nextcloud
```

</details>

## 5. MOUNTING SAMBA

Mount Samba drive residing on Sternicza _Linksys_ router.

```bash
sudo mount \
  --source //192.168.2.1/lukasz \
  --target /mnt/smb/lukasz \
  --types cifs \
  --options user=lukasz \
  ,password=***** \
  ,iocharset=utf8,vers=1.0 \
  ,dir_mode=0777,file_mode=0777,nounix
```

## 6. BORG BACKUP

### 6.1. Create _archive_

From **NextcloudPi** to USB drive mounted on _DietPi_ (raspberry).

```bash
borg create \
  --stats \
  root@192.168.2.145:/mnt/usb/nextcloudbackup::{hostname}-{now:%Y%m%dT%H%M} \
  /mnt/btrfs/ncdata/data/lukasz/files
```

<details>
<summary>...with dry run.</summary>

```bash
borg create \
  --list \
  --dry-run \
  --filter - \
  root@192.168.2.145:/mnt/usb/nextcloudbackup::{hostname}-{now:%Y%m%dT%H%M} \
  /mnt/btrfs/ncdata/data/lukasz/files
```

</details>

From **NUC** to USB drive mounted on _DietPi_ (raspberry).

```bash
borg create \
  --stats --patterns-from ~/Code/helper/admin/other/backup_patt.txt \
  root@192.168.2.145:/mnt/usb/nucbackup::{hostname}-{now:%Y%m%dT%H%M} \
  ~
```

### 6.2. Get info

Information on _repository_.

```bash
borg info \
  root@192.168.2.145:/mnt/usb/nextcloudbackup
```

List _archives_ in repository.

```bash
borg list \
  root@192.168.2.145:/mnt/usb/nextcloudbackup
```

Verify consistnecy of _repository_.

```bash
borg check \
  --verbose --repository-only \
  root@192.168.2.145:/mnt/usb/nextcloudbackup
```

### 6.3. Vorta to NextcloudPi backup

<details>
<summary>Not realy usefull.</summary>

```bash
source ~/homenv/bin/activate.fish
```

```bash
set -lx BORG_PASSCOMMAND "cat $HOME/.borg-nextcloud-passphrase" \
  && vorta
```

</details>

### 6.4. Prune

Remove extra _archives_.

```bash
borg prune -v --list --dry-run --keep-daily=7 --keep-weekly=4 --keep-monthly=-1 \
  root@192.168.2.145:/mnt/usb/nextcloudbackup
```

## 7. NEXTCLOUDPi SETUP

### 7.1. Hardware

```bash
netboot_default
```

### 7.2. Debian

Install _Debian_.

#### ssh for user

```bash
sudo su
su -
groups
```

Adding user to _sudoers_ group.

```bash
usermod --append --groups sudo la_lukasz
```

Copying the public key to _192.168.2.120_

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub la_lukasz@192.168.2.120
```

Turn off _Password authentication_.

```bash
sudo nano /etc/ssh/sshd_config
```

```bash
sudo systemctl restart ssh
```

#### Better file system BTRFS

Check [format-a-harddisk-partition](https://vitux.com/how-to-format-a-harddisk-partition-with-btrfs-on-ubuntu-20-04/) and [btrfs-on-ubuntu](https://www.linuxfordevices.com/tutorials/linux/btrfs-on-ubuntu) pages.

```bash
su -
```

```bash
apt install btrfs-progs
```

```bash
lsblk
mount
fdisk --list
df --all --print-type --si
cfdisk
```

```bash
cat /proc/mounts
ls /dev/disk/
ls /dev/disk/by-uuid
```

```bash
findmnt
findmnt --fstab
findmnt --evaluate
```

```bash
sudo fdisk /dev/sdb
sudo partprobe /dev/sdb
sudo ls -l /dev | grep sd
sudo mkfs.btrfs --label btrfs /dev/sdb1
```

```bash
sudo mkdir /mnt/btrfs
sudo mount /dev/sdb1 /mnt/btrfs
```

```bash
findmnt --mtab --json --output UUID,SOURCE
sudo nano /etc/fstab
```

Append _fstab_ line.

```text
UUID=0bcd6094-3899-488f-8733-19f824e3be8c /mnt/btrfs btrfs defaults 0 3
```

### 7.3. Install

#### Nextcloud install on Debian

Check [curl-installer-debian](https://help.nextcloud.com/t/curl-installer-debian/126327) script.

#### Moving data directory

Check [move-data-directory](https://help.nextcloud.com/t/howto-change-move-data-directory-after-installation/17170) page.

```bash
sudo su -
sudo bash
sudo ncp-config
```

```bash
sudo nano /var/www/nextcloud/config/config.php
```

#### Permisions

Check [permissions](https://help.nextcloud.com/t/frequently-asked-questions-faq-ncp/126325#what-userpermissions-should-i-have-to-the-external-usb-drive-mount-point-the-ncdata-and-ncdatabase-directory-11).

What user/permissions should I have to the external USB drive mount point, the ncdata and ncdatabase directory?

| Directory      | User       | Group      | Permissions  | Permission mask |
| -------------- | ---------- | ---------- | ------------ | --------------- |
| `Mount_Point/` | `root`     | `root`     | `drwxr-x–x`  | `751`           |
| `ncdata/`      | `www-data` | `www-data` | `drwxr-x—`   | `750`           |
| `ncdatabase`   | `mysql`    | `mysql`    | `drwxr-xr-x` | `755`           |

#### Admining

```bash
sudo -u www-data bash
```

```bash
cd /var/www/nextcloud
```

```bash
php occ
```

Check [occ command](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html) manual.

#### Activation

> Your NextCloudPi user is `ncp`
>
>Your NextCloudPi password is `***`
>
> Save this password in order to access to the NextCloudPi web interface at [https://nextcloudpi.local:4443](https://nextcloudpi.local:4443). This password can be changed using `nc-passwd`
>
> Your NextCloud user is `ncp`
>
>Your Nextcloud password is `***`
>
>Save this password in order to access NextCloud [https://nextcloudpi.local](https://nextcloudpi.local). This password can be changed from the Nextcloud user configuration.
