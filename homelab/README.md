# PRIVATE CLOUD SETUP

- [1. Hardware](#1-hardware)
- [2. Debian](#2-debian)
  - [2.1. ssh for user](#21-ssh-for-user)
  - [2.2. Better file system BTRFS](#22-better-file-system-btrfs)
  - [2.3. Docker](#23-docker)
- [3. paperless-ngx _docker_](#3-paperless-ngx-docker)
  - [3.1. Install](#31-install)
  - [3.2. Admining](#32-admining)
- [4. Nextcloud AIO _docker_](#4-nextcloud-aio-docker)
  - [4.1. Install](#41-install)
  - [4.2. Admining](#42-admining)
- [5. PiHole on _docker_ at _odroid_](#5-pihole-on-docker-at-odroid)
  - [5.1. Static IP](#51-static-ip)
  - [5.2. docker-compose.yml](#52-docker-composeyml)

## 1. Hardware

:information_source: Odroid only.

```bash
exit
netboot_default
exit
```

## 2. Debian

Install _Debian_.

### 2.1. ssh for user

```bash
sudo su -
groups
```

Adding user to _sudoers_ group.

```bash
sudo usermod --append --groups sudo la_lukasz
sudo usermod --append --groups root la_lukasz
```

Copying the public key to _odroid_

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub la_lukasz@odroid.lan
```

Turn off _Password authentication_.

```bash
sudo nano /etc/ssh/sshd_config
```

```bash
sudo systemctl restart ssh
```

Generating user key.

```bash
ssh-keygen -t ed25519
```

```bash
scp -Crp \
  la_lukasz@odroid.lan:/home/la_lukasz/.ssh/id_ed25519 \
  ~/tmp
scp -Crp \
  la_lukasz@odroid.lan:/home/la_lukasz/.ssh/id_ed25519.pub \
  ~/tmp
```

### 2.2. Better file system BTRFS

:information_source: Check [format-a-harddisk-partition](https://vitux.com/how-to-format-a-harddisk-partition-with-btrfs-on-ubuntu-20-04/) and [btrfs-on-ubuntu](https://www.linuxfordevices.com/tutorials/linux/btrfs-on-ubuntu) pages.

```bash
sudo apt install btrfs-progs
```

#### Look around

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

#### Do

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

### 2.3. Docker

:information_source: Installation of _docker-compose_ contains _docker_ itself.

```bash
sudo apt install docker-compose
usermod --append --groups docker la_lukasz
```

## 3. paperless-ngx _docker_

### 3.1. Install

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

### 3.2. Admining

#### Chown and chmod

```bash
sudo chown --recursive la_lukasz:la_lukasz \
  /home/la_lukasz/paperless-ngx/consume \
  && sudo find /home/la_lukasz/paperless-ngx/consume -type d -print0 \
    | xargs -0 sudo -u la_lukasz chmod u=rwx,g=rx \
  && sudo find /home/la_lukasz/paperless-ngx/consume -type f -print0 \
    | xargs -0 sudo -u la_lukasz chmod u=rw,g=r
```

#### Ingest email

```bash
docker exec -it paperless_webserver_1 \
  mail_fetcher
```

#### General maintenance

```bash
docker exec -it paperless_webserver_1 \
  document_index reindex
docker exec -it paperless_webserver_1 \
  document_sanity_checker
docker exec -it paperless_webserver_1 \
  document_create_classifier
docker exec -it paperless_webserver_1 \
  document_retagger -c -t -T --use-first
docker exec -it paperless_webserver_1 \
  document_thumbnails
```

## 4. Nextcloud AIO _docker_

### 4.1. Install

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

```bash
sudo usermod --append --groups www-data la_lukasz
```

<details>
<summary>Nextcloud<b>Pi</b> install on Debian. :warning:</summary>

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

#### Brute force exemption

:information_source: See [this](https://mxtoolbox.com/subnetcalculator.aspx) toolbox.

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ config:list bruteForce
```

```json
{
    "apps": {
        "bruteForce": {
            "whitelist_1": "192.168.2.1\/32"
        }
    }
}
```

### 4.2. Admining

#### Chown and chmod

```bash
sudo chown --recursive www-data:www-data \
  /mnt/btrfs \
  && sudo find /mnt/btrfs -type d -print0 \
    | xargs -0 sudo -u www-data chmod u=rwx,g=rx \
  && sudo find /mnt/btrfs -type f -print0 \
    | xargs -0 sudo -u www-data chmod u=rw,g=r
```

#### Commands occ list

:information_source: Check [occ command](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html) manual.

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ list
```

#### Rescan

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ files:scan --all \
  ; sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
    php occ files:scan-app-data
```

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ maps:scan-photos \
  ; sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
    php occ photos:map-media-to-place \
  ; sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
    php occ preview:generate
```

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ trashbin:cleanup --all-users \
  ; sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
    php occ versions:cleanup
```

```bash
sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ memories:index
```

```bash
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

#### Permisions :warning:

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

## 5. PiHole on _docker_ at _odroid_

```bash
ip --color route | grep default
ip --color addr show
```

:information_source: Please note if `end0` is the interface.

### 5.1. Static IP

```bash
sudo nano /etc/network/interfaces.d/end0
```

```text
allow-hotplug end0
iface end0 inet static
address 192.168.2.2
netmask 255.255.255.0
gateway 192.168.2.1
dns-nameservers 127.0.0.1
dns-nameservers 8.8.8.8
```

```bash
sudo systemctl restart networking
ip -c addr show
```

### 5.2. docker-compose.yml

```text
version: "3"

# More info at https://github.com/pi-hole/docker-pi-hole/
# and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    # For DHCP it is recommended to remove these ports
    # and instead add: network_mode: "host"
    # ports:
      # - "53:53/tcp"
      # - "53:53/udp"
      # - "67:67/udp" # Only required if you are using Pi-hole as your DHCP server
      # - "80:80/tcp"
    network_mode: host
    environment:
      TZ: 'Europe/Berlin'
      WEBPASSWORD: '***[redacted]***'
      INTERFACE: end0
      FTLCONF_LOCAL_IPV4: 192.168.2.2
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
    restart: unless-stopped
```

```bash
docker compose up -d
```