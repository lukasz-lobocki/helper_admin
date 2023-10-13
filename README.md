# ADMIN

```bash
sudo apt update && sudo apt upgrade \
  && sudo apt autoclean && sudo apt clean \
  && sudo apt autoremove
```

```bash
sudo apt --with-new-pkgs upgrade <pckgs-lst>
```

## TABLE OF CONTENTS <!-- omit in toc -->

- [1. CHEATSHEET](#1-cheatsheet)
- [2. FILES HANDLING](#2-files-handling)
  - [2.1. Ownership](#21-ownership)
  - [2.2. Permisions](#22-permisions)
  - [2.3. Hashing](#23-hashing)
  - [2.4. Indexing](#24-indexing)
- [3. REMOTE COPYING with scp](#3-remote-copying-with-scp)
- [4. REMOTE SYNCHRONIZE with rsync](#4-remote-synchronize-with-rsync)
- [5. MOUNTING SAMBA](#5-mounting-samba)
- [6. BORG BACKUP](#6-borg-backup)
  - [6.1. Create _archive_](#61-create-archive)
  - [6.2. Get info](#62-get-info)
  - [6.3. Prune](#63-prune)
  - [6.4. Vorta to NextcloudPi backup](#64-vorta-to-nextcloudpi-backup)
- [7. SUDO-ing](#7-sudo-ing)
- [8. PRIVATE CLOUD SETUP](#8-private-cloud-setup)
  - [8.1. Hardware](#81-hardware)
  - [8.2. Debian](#82-debian)
  - [8.3. paperless-ngx _docker_ install](#83-paperless-ngx-docker-install)
  - [8.4. Nextcloud AIO _docker_ install](#84-nextcloud-aio-docker-install)
  - [8.5. Admining](#85-admining)

## 1. CHEATSHEET

:information_source: Check [Bash scripting cheatsheet](https://devhints.io/bash) and [how-to-use-double-or-single-brackets-parentheses-curly-braces](https://stackoverflow.com/a/2188223/4465044) pages.

:information_source: Check [TOC generator](https://luciopaiva.com/markdown-toc/) page.

## 2. FILES HANDLING

### 2.1. Ownership

```bash
sudo \
  chown --recursive www-data:www-data /mnt/btrfs
```

### 2.2. Permisions

:information_source: Check [nextcloud permisions](https://docs.nextcloud.com/server/13/admin_manual/maintenance/manual_upgrade.html) and [gist permisions](#permisions) pages.

#### Directories

```bash
sudo \
  find /mnt/btrfs -type d -print0 \
  | xargs -0 sudo -u www-data \
    chmod u=rwx,g=rx
```

#### Files

```bash
sudo \
  find /mnt/btrfs -type f -print0 \
  | xargs -0 sudo -u www-data \
    chmod u=rw,g=r
```

### 2.3. Hashing

:information_source: Check [file-append_xxhsum.sh](https://github.com/lukasz-lobocki/helper_admin/blob/main/other/append_xxhsum.sh) and [append-xxhsum](https://github.com/lukasz-lobocki/append-xxhsum.git) pages.

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

### 2.4. Indexing

:information_source: Check [How to disable file indexing in Ubuntu](https://stackoverflow.com/a/76178044/4465044) post.

## 3. REMOTE COPYING with scp

With <u>__C__</u>ompression in transit, <u>__r__</u>ecursively, <u>__p__</u> preserving modification timestamps.

```bash
scp -Crp ./directory/ username@to_host:./directory/
```

## 4. REMOTE SYNCHRONIZE with rsync

Re-synchronizes whole __Nextcloud__ into _Slonecznikowa_.

```bash
ssh la_lukasz@192.168.2.120 \
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
  --delete \
  -e ssh \
  /mnt/btrfs/lukasz/files \
  la_lukasz@lobocki.ddns.net:base/ster_nextcloud
```

Re-synchronizes whole __Paperless__ into _Slonecznikowa_.

```bash
ssh la_lukasz@192.168.2.120 \
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
  --delete \
  -e ssh \
  ~/paperless-ngx/media/documents/originals \
  la_lukasz@lobocki.ddns.net:base/ster_paperless
```

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

#### Nextcloud

From __Nextcloud__ to USB drive mounted on _DietPi_ (raspberry).

```bash
borg create \
  --stats \
  root@192.168.2.145:/mnt/usb/nextcloudbackup::{hostname}-{now:%Y%m%dT%H%M} \
  /mnt/btrfs/lukasz/files
```

<details>
<summary>...with dry run.</summary>

```bash
borg create \
  --list \
  --dry-run \
  --filter - \
  root@192.168.2.145:/mnt/usb/nextcloudbackup::{hostname}-{now:%Y%m%dT%H%M} \
  /mnt/btrfs/lukasz/files
```

</details>

<details>
<summary>...same for <b>NUC11</b>.</summary>

From __NUC11__ to USB drive mounted on _DietPi_ (raspberry).

```bash
borg create \
  --stats --patterns-from ~/Code/helper/admin/other/backup_patt.txt \
  root@192.168.2.145:/mnt/usb/nuc11backup::{hostname}-{now:%Y%m%dT%H%M} \
  ~
```

</details>

<details>
<summary>...same for <b>NUC13</b>.</summary>

From __NUC13__ to USB drive mounted on _DietPi_ (raspberry).

```bash
borg create \
  --stats --patterns-from ~/Code/helper/admin/other/backup_patt.txt \
  root@192.168.2.145:/mnt/usb/nuc13backup::{hostname}-{now:%Y%m%dT%H%M} \
  ~
```

</details>

### 6.2. Get info

Information on _repository_.

#### Nextcloud

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

<details>
<summary>...same for <b>NUC</b>.</summary>

```bash
borg info \
  root@192.168.2.145:/mnt/usb/nucbackup
```

List _archives_ in repository.

```bash
borg list \
  root@192.168.2.145:/mnt/usb/nucbackup
```

Verify consistnecy of _repository_.

```bash
borg check \
  --verbose --repository-only \
  root@192.168.2.145:/mnt/usb/nucbackup
```

</details>

### 6.3. Prune

Remove extra _archives_.

#### Nextcloud

```bash
borg prune -v --list --dry-run --keep-daily=7 --keep-weekly=4 --keep-monthly=-1 \
  root@192.168.2.145:/mnt/usb/nextcloudbackup
```

<details>
<summary>...same for <b>NUC</b>.</summary>

```bash
borg prune -v --list --dry-run --keep-daily=7 --keep-weekly=4 --keep-monthly=-1 \
  root@192.168.2.145:/mnt/usb/nucbackup
```

</details>

### 6.4. Vorta to NextcloudPi backup

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

## 7. SUDO-ing

:information_source: The commands `su`, `su -`, `sudo su -`, and `sudo -i` are all used in the Linux terminal to switch users or elevate privileges. However, they have some differences in their behavior.

- `su`: This command stands for "switch user" and is used to log in as a different user. When you run `su` without any arguments, it will switch to the root user by default. You'll be prompted to enter the password of the user you're switching to.
- `su -`: The - (dash) option with `su` is used to simulate a login session for the new user. It sets the environment variables, shell, and working directory to that of the new user. This is useful if you need to perform tasks as that user and need access to their environment. New user name is to be provided after dash: `su - www-data`
- `sudo su -`: The `sudo` command is used to execute a command with elevated privileges. When you run `sudo su -`, you're using `sudo` to execute the `su -` command as the root user. This is a quick way to switch to the root user without having to enter the root password.
- `sudo -i`: This command is similar to sudo `su -`. The `-i` option stands for "login" and simulates a login session for the target user, in this case, the root user. This means that the root user's environment variables, shell, and working directory are used. It's also a quick way to get a root shell.

## 8. PRIVATE CLOUD SETUP

### 8.1. Hardware

:information_source: Odroid only.

```bash
netboot_default
```

### 8.2. Debian

Install _Debian_.

#### ssh for user

```bash
sudo su -
groups
```

Adding user to _sudoers_ group.

```bash
usermod --append --groups sudo la_lukasz
usermod --append --groups root la_lukasz
```

Copying the public key to _192.168.2.120_

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub la_lukasz@192.168.2.120
```

Turn off _Password authentication_.

```bash
sudo nano /etc/ssh/sshd_config
```

```bash
sudo systemctl restart ssh
```

#### Better file system BTRFS

:information_source: Check [format-a-harddisk-partition](https://vitux.com/how-to-format-a-harddisk-partition-with-btrfs-on-ubuntu-20-04/) and [btrfs-on-ubuntu](https://www.linuxfordevices.com/tutorials/linux/btrfs-on-ubuntu) pages.

```bash
sudo apt install btrfs-progs
```

##### Look around

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

##### Do

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

#### Docker

```bash
sudo apt install docker-compose
usermod --append --groups docker la_lukasz
```

### 8.3. paperless-ngx _docker_ install

:information_source: Check [docs.paperless-ngx](https://docs.paperless-ngx.com/) site.

#### TCP port

:information_source: `8081`

#### Configuration in _docker-compose.env_

```bash
nano /home/la_lukasz/paperless-ngx/docker-compose.env
```

Append following lines.

```text
PAPERLESS_TASK_WORKERS=2
PAPERLESS_THREADS_PER_WORKER=1
PAPERLESS_WEBSERVER_WORKERS=1
PAPERLESS_WORKER_TIMEOUT=1800
PAPERLESS_OCR_MODE=skip
PAPERLESS_OCR_SKIP_ARCHIVE_FILE=with_text
PAPERLESS_OCR_PAGES=3
PAPERLESS_CONVERT_MEMORY_LIMIT=32
PAPERLESS_ENABLE_NLTK=false
PAPERLESS_OCR_CLEAN=none
PAPERLESS_OCR_DESKEW=false
PAPERLESS_OCR_ROTATE_PAGES=true
PAPERLESS_OCR_OUTPUT_TYPE=pdf
PAPERLESS_CONSUMER_RECURSIVE=true
PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS=true
```

```bash
docker-compose up -d
docker exec -it paperless_webserver_1 printenv
```

### 8.4. Nextcloud AIO _docker_ install

```bash
sudo docker run \
--init \
--sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart always \
--publish 80:80 \
--publish 8080:8080 \
--publish 8443:8443 \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
-e NEXTCLOUD_DATADIR="/mnt/btrfs/nextcloud" \
-e NEXTCLOUD_MOUNT="/home/la_lukasz/paperless-ngx" \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
nextcloud/all-in-one:latest
```

<details>
<summary>Nextcloud<b>Pi</b> install on Debian.</summary>

:information_source: Check [curl-installer-debian](https://help.nextcloud.com/t/curl-installer-debian/126327) script.

:information_source: Check [move-data-directory](https://help.nextcloud.com/t/howto-change-move-data-directory-after-installation/17170) page.
</details>

#### Use External Storage app

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ files_external -h
```

```json
[
    {
        "mount_id": 1,
        "mount_point": "\/Paperless",
        "storage": "\\OC\\Files\\Storage\\Local",
        "authentication_type": "null::null",
        "configuration": {
            "datadir": "\/home\/la_lukasz\/paperless-ngx\/media\/documents\/originals"
        },
        "options": {
            "enable_sharing": false,
            "encoding_compatibility": false,
            "encrypt": true,
            "filesystem_check_changes": 1,
            "previews": true,
            "readonly": true
        },
        "applicable_users": [],
        "applicable_groups": []
    },
    {
        "mount_id": 2,
        "mount_point": "\/Consume",
        "storage": "\\OC\\Files\\Storage\\Local",
        "authentication_type": "null::null",
        "configuration": {
            "datadir": "\/home\/la_lukasz\/paperless-ngx\/consume"
        },
        "options": {
            "enable_sharing": false,
            "encoding_compatibility": false,
            "encrypt": true,
            "filesystem_check_changes": 1,
            "previews": false,
            "readonly": false
        },
        "applicable_users": [],
        "applicable_groups": []
    }
]
```

### 8.5. Admining

```bash
sudo usermod --append --groups www-data la_lukasz
```

#### Chown and chmod

##### Nextcloud

```bash
sudo chown --recursive www-data:www-data \
  /mnt/btrfs \
  && sudo find /mnt/btrfs -type d -print0 \
    | xargs -0 sudo -u www-data chmod u=rwx,g=rx \
  && sudo find /mnt/btrfs -type f -print0 \
    | xargs -0 sudo -u www-data chmod u=rw,g=r
```

##### Paperless

```bash
sudo chown --recursive la_lukasz:la_lukasz \
  /home/la_lukasz/paperless-ngx/consume \
  && sudo find /home/la_lukasz/paperless-ngx/consume -type d -print0 \
    | xargs -0 sudo -u la_lukasz chmod u=rwx,g=rx
  && sudo find /home/la_lukasz/paperless-ngx/consume -type f -print0 \
    | xargs -0 sudo -u la_lukasz chmod u=rw,g=r
```

#### occ commands

:information_source: Check [occ command](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html) manual.

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ list
```

#### Rescan

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ files:scan --all
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ files:scan-app-data
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ maps:scan-photos
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ photos:map-media-to-place
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ preview:generate
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ trashbin:cleanup --all-users
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ versions:cleanup
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php -d memory_limit=2G occ fulltextsearch:index \
  --no-interaction --no-warnings --no-readline
```

#### Editting _config.php_

```bash
sudo docker run \
  -it --rm --volume nextcloud_aio_nextcloud:/var/www/html:rw alpine \
  sh -c "apk add --no-cache nano \
  && nano /var/www/html/config/config.php"
```

```bash
sudo nano /var/www/nextcloud/config/config.php
```

#### Illegal filenames

:information_source: Check [detox](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjh1vPbi9mBAxUa4QIHHWD9CqoQFnoECBcQAQ&url=https%3A%2F%2Flinux.die.net%2Fman%2F1%2Fdetox&usg=AOvVaw0GGiH9PguA-A1-H4MWUF-o&opi=89978449) command.

:information_source: Check [this](other/detoxrc) out.

```bash
detox -f ~/Code/helper/admin/other/detoxrc \
  -s lobo-uni -r -v -n ~/Code
```

#### Permisions

:information_source: Check [permissions](https://help.nextcloud.com/t/frequently-asked-questions-faq-ncp/126325#what-userpermissions-should-i-have-to-the-external-usb-drive-mount-point-the-ncdata-and-ncdatabase-directory-11).

What user/permissions should I have to the external USB drive mount point, the ncdata and ncdatabase directory?

| Directory      | User       | Group      | Permissions  | Permission mask |
| -------------- | ---------- | ---------- | ------------ | --------------- |
| `Mount_Point/` | `root`     | `root`     | `drwxr-x–x`  | `751`           |
| `ncdata/`      | `www-data` | `www-data` | `drwxr-x—`   | `750`           |
| `ncdatabase`   | `mysql`    | `mysql`    | `drwxr-xr-x` | `755`           |

```bash
cd /var/www/nextcloud
```

#### 8.6. Ingest email

```text
docker exec -it paperless_webserver_1 mail_fetcher
```
