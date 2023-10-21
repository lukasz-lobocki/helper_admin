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
  - [6.1. From _NUC13_ to _odroid_](#61-from-nuc13-to-odroid)
  - [6.2. From _Nextcloud_ to _odroid_](#62-from-nextcloud-to-odroid)
  - [6.3. From _paperless_ to _odroid_](#63-from-paperless-to-odroid)
- [7. SUDO-ing](#7-sudo-ing)

## 1. CHEATSHEET

:information_source: Check [Bash scripting cheatsheet](https://devhints.io/bash) and [how-to-use-double-or-single-brackets-parentheses-curly-braces](https://stackoverflow.com/a/2188223/4465044) pages.

## 2. FILES HANDLING

### 2.1. Ownership

```bash
sudo \
  chown --recursive www-data:www-data /mnt/btrfs
```

### 2.2. Permisions

:information_source: Check [nextcloud permisions](https://docs.nextcloud.com/server/13/admin_manual/maintenance/manual_upgrade.html) and [gist permisions]([#permisions-warning](https://github.com/lukasz-lobocki/helper_admin/tree/main/homelab#permisions-warning)) pages.

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
<summary>Creation alternative with rhash. :warning:</summary>

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

With <u>__C__</u>ompression in transit, <u>__r__</u>ecursively, <u>__p__</u>reserving modification timestamps.

```bash
scp -Crp ./directory/ username@to_host:./directory/
```

## 4. REMOTE SYNCHRONIZE with rsync

Re-synchronizes __Nextcloud__ data into _Slonecznikowa_.

```bash
ssh la_lukasz@NUC11ATK \
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
    --rsh=ssh \
  /mnt/btrfs/lukasz/files \
  la_lukasz@lobocki.ddns.net:base/ster_nextcloud
```

Re-synchronizes __Paperless__ data into _Slonecznikowa_.

```bash
ssh la_lukasz@NUC11ATK \
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
    --rsh=ssh \
  /home/la_lukasz/paperless-ngx/media/documents/originals \
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

### 6.1. From _NUC13_ to _odroid_

Create _repository_.

```bash
borg init \
  --encryption repokey \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13

borg key export \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13 \
  ~/tmp/borg-key-nuc13
```

Create _archive_ (backup) in repository.

```bash
borg create \
  --stats --list --patterns-from ~/Code/helper/admin/other/backup_patt.txt \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13::{hostname}-{now:%Y%m%dT%H%M} \
  ~
```

Information on _repository_.

```bash
borg info \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13
```

List _archives_ in repository.

```bash
borg list \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13
```

Verify consistency of _repository_.

```bash
borg check \
  --verbose --repository-only \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13
```

Prune extra _archives_.

```bash
borg prune \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=-1 \
  --verbose --list --dry-run \
  la_lukasz@odroid:/mnt/btrfs/backup/nuc13
```

### 6.2. From _Nextcloud_ to _odroid_

```bash
ssh la_lukasz@nuc11atk

borg create \
  --stats --list --one-file-system \
  la_lukasz@odroid:/mnt/btrfs/backup/nextcloud::{hostname}-{now:%Y%m%dT%H%M} \
  /mnt/btrfs/lukasz/files
```

### 6.3. From _paperless_ to _odroid_

```bash
ssh la_lukasz@nuc11atk

borg create \
  --stats --list --one-file-system \
  la_lukasz@odroid:/mnt/btrfs/backup/paperless::{hostname}-{now:%Y%m%dT%H%M} \
  /home/la_lukasz/paperless-ngx/media/documents/originals
```

## 7. SUDO-ing

:information_source: The commands `su`, `su -`, `sudo su -`, and `sudo -i` are all used in the Linux terminal to switch users or elevate privileges. However, they have some differences in their behavior.

- `su`: This command stands for "switch user" and is used to log in as a different user. When you run `su` without any arguments, it will switch to the root user by default. You'll be prompted to enter the password of the user you're switching to.
- `su -`: The - (dash) option with `su` is used to simulate a login session for the new user. It sets the environment variables, shell, and working directory to that of the new user. This is useful if you need to perform tasks as that user and need access to their environment. New user name is to be provided after dash: `su - www-data`
- `sudo su -`: The `sudo` command is used to execute a command with elevated privileges. When you run `sudo su -`, you're using `sudo` to execute the `su -` command as the root user. This is a quick way to switch to the root user without having to enter the root password.
- `sudo -i`: This command is similar to sudo `su -`. The `-i` option stands for "login" and simulates a login session for the target user, in this case, the root user. This means that the root user's environment variables, shell, and working directory are used. It's also a quick way to get a root shell.
