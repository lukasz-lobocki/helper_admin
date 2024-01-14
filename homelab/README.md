# PRIVATE CLOUD SETUP

- [1. Hardware](#1-hardware)
- [2. Install Debian](#2-install-debian)
  - [2.1. ssh for user](#21-ssh-for-user)
  - [2.2. Better file system BTRFS](#22-better-file-system-btrfs)
  - [2.3. Docker](#23-docker)
- [3. Setup _paperless-ngx_ on _docker_ at _NUC11ATK_](#3-setup-paperless-ngx-on-docker-at-nuc11atk)
  - [3.1. Install](#31-install)
  - [3.2. Admining](#32-admining)
- [4. Setup _Nextcloud AIO_ and _caddy_ reverse-proxy on _docker_ at _NUC11ATK_](#4-setup-nextcloud-aio-and-caddy-reverse-proxy-on-docker-at-nuc11atk)
  - [4.1. Install](#41-install)
  - [4.2. Admining](#42-admining)
- [5. Setup _PiHole_ on _docker_ at _odroid_](#5-setup-pihole-on-docker-at-odroid)
  - [5.1. Install](#51-install)
- [6. Setup _Vaultwarden_ on _docker_ at _NUC11ATK_](#6-setup-vaultwarden-on-docker-at-nuc11atk)
  - [6.1. Install](#61-install)
- [7. Setup _smallstep_ CA PKI on _docker_ at _odroid_](#7-setup-smallstep-ca-pki-on-docker-at-odroid)
  - [7.1. Install](#71-install)
  - [7.2. Admining](#72-admining)

## 1. Hardware

:information_source: Odroid only.

```bash
exit
netboot_default
exit
```

## 2. Install Debian

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

#### Portainer

```bash
docker pull portainer/portainer-ce:latest
```

```bash
docker run -d -p 9443:9443 --name=portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  -v ~/portainer/certs:/certs \
  portainer/portainer-ce:latest \
  --sslcert /certs/nuc11atk.lan.crt \
  --sslkey /certs/nuc11atk.lan.key
```

## 3. Setup _paperless-ngx_ on _docker_ at _NUC11ATK_

### 3.1. Install

:information_source: Check [docs.paperless-ngx](https://docs.paperless-ngx.com/) site.

#### TCP port

:information_source: `:8081`

#### _docker-compose.yml_

```yaml
# To install and update paperless with this file, do the following:
#
# - Copy this file as 'docker-compose.yml' and the files 'docker-compose.env'
#   and '.env' into a folder.
# - Run 'docker-compose pull'.
# - Run 'docker-compose run --rm webserver createsuperuser' to create a user.
# - Run 'docker-compose up -d'.
#
# For more extensive installation and update instructions, refer to the
# documentation.

version: "3.4"
services:
  broker:
    image: docker.io/library/redis:7
    restart: unless-stopped
    volumes:
      - redisdata:/data

  db:
    image: docker.io/library/postgres:15
    restart: unless-stopped
    volumes:
      - /home/la_lukasz/paperless-ngx/dbase:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: paperless

  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      - db
      - broker
    ports:
      - "8081:8000"
    healthcheck:
      test: ["CMD", "curl", "-fs", "-S", "--max-time", "2", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - ./data:/usr/src/paperless/data
      - /mnt/btrfs/paperless/media:/usr/src/paperless/media
      - ./export:/usr/src/paperless/export
      - ./consume:/usr/src/paperless/consume
      - ./scripts:/usr/src/paperless/scripts
    env_file: docker-compose.env
    environment:
      PAPERLESS_REDIS: redis://broker:6379
      PAPERLESS_DBHOST: db

volumes:
  redisdata:
```

#### _docker-compose.env_

```ini
PAPERLESS_URL=https://paperless.lobocki.duckdns.org
PAPERLESS_SECRET_KEY=***[redacted]***
PAPERLESS_TRUSTED_PROXIES=127.0.0.1
PAPERLESS_ALLOWED_HOSTS=localhost # use only with caddy
PAPERLESS_TIME_ZONE=Europe/Warsaw
PAPERLESS_OCR_LANGUAGE=pol+eng
PAPERLESS_OCR_LANGUAGES=pol eng
PAPERLESS_TASK_WORKERS=2
PAPERLESS_THREADS_PER_WORKER=1
PAPERLESS_WEBSERVER_WORKERS=1
PAPERLESS_WORKER_TIMEOUT=1800
PAPERLESS_OCR_MODE=skip
PAPERLESS_OCR_SKIP_ARCHIVE_FILE=with_text
PAPERLESS_OCR_PAGES=3
PAPERLESS_CONVERT_MEMORY_LIMIT=32
PAPERLESS_ENABLE_NLTK=true
PAPERLESS_OCR_CLEAN=none
PAPERLESS_OCR_DESKEW=false
PAPERLESS_OCR_ROTATE_PAGES=true
PAPERLESS_OCR_OUTPUT_TYPE=pdf
PAPERLESS_CONSUMER_RECURSIVE=true
PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS=true
PAPERLESS_DATE_ORDER=YMD
PAPERLESS_PRE_CONSUME_SCRIPT=/usr/src/paperless/scripts/removepassword.py
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
docker exec -it paperless-webserver-1 \
  document_index reindex
docker exec -it paperless-webserver-1 \
  document_sanity_checker
docker exec -it paperless-webserver-1 \
  document_create_classifier
docker exec -it paperless-webserver-1 \
  document_retagger -c -t -T --use-first
docker exec -it paperless-webserver-1 \
  document_thumbnails
```

## 4. Setup _Nextcloud AIO_ and _caddy_ reverse-proxy on _docker_ at _NUC11ATK_

### 4.1. Install

```bash
sudo usermod --append --groups www-data,docker,root,sudo la_lukasz
```

#### docker-compose.yml

```yaml
services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    init: true
    restart: always
    container_name: nextcloud-aio-mastercontainer
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - caddy
    ports:
      - 8080:8080
      # Can be removed when running behind a web server or reverse proxy (like Apache, Nginx, Cloudflare Tunnel and else). See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      # - 80:80      
      # Can be removed when running behind a web server or reverse proxy (like Apache, Nginx, Cloudflare Tunnel and else). See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      # - 8443:8443    
    networks:
      # Is needed when you want to create the nextcloud-aio network with ipv6-support using this file, see the network config at the bottom of the file
      - nextcloud-aio
    environment:
      # Allows to set the host directory for Nextcloud's datadir. Warning: do not set or adjust this value after the initial Nextcloud installation is done! See https://github.com/nextcloud/all-in-one#how-to-change-the-default-location-of-nextclouds-datadir
      - NEXTCLOUD_DATADIR=/mnt/btrfs/nextcloud
      # Allows the Nextcloud container to access the chosen directory on the host. See https://github.com/nextcloud/all-in-one#how-to-allow-the-nextcloud-container-to-access-directories-on-the-host
      - NEXTCLOUD_MOUNT=/home/la_lukasz/paperless-ngx
      # Is needed when running behind a web server or reverse proxy (like Apache, Nginx, Cloudflare Tunnel and else). See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      - APACHE_PORT=11000
      # Should be set when running behind a web server or reverse proxy (like Apache, Nginx, Cloudflare Tunnel and else) that is running on the same host. See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      - APACHE_IP_BINDING=127.0.0.1
      # Setting this to true allows to hide the backup section in the AIO interface. See https://github.com/nextcloud/all-in-one#how-to-disable-the-backup-section
      # - AIO_DISABLE_BACKUP_SECTION=false      
      # Allows to adjust borgs retention policy. See https://github.com/nextcloud/all-in-one#how-to-adjust-borgs-retention-policy
      # - BORG_RETENTION_POLICY=--keep-within=7d --keep-weekly=4 --keep-monthly=6      
      # Setting this to true allows to disable Collabora's Seccomp feature. See https://github.com/nextcloud/all-in-one#how-to-disable-collaboras-seccomp-feature
      # - COLLABORA_SECCOMP_DISABLED=false      
      # Can be adjusted if you need more. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-upload-limit-for-nextcloud
      # - NEXTCLOUD_UPLOAD_LIMIT=10G      
      # Can be adjusted if you need more. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-max-execution-time-for-nextcloud
      # - NEXTCLOUD_MAX_TIME=3600      
      # Can be adjusted if you need more. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-php-memory-limit-for-nextcloud
      # - NEXTCLOUD_MEMORY_LIMIT=512M
      # CA certificates in this directory will be trusted by the OS of the nexcloud container (Useful e.g. for LDAPS) See See https://github.com/nextcloud/all-in-one#how-to-trust-user-defined-certification-authorities-ca
      # - NEXTCLOUD_TRUSTED_CACERTS_DIR=/path/to/my/cacerts
      # Allows to modify the Nextcloud apps that are installed on starting AIO the first time. See https://github.com/nextcloud/all-in-one#how-to-change-the-nextcloud-apps-that-are-installed-on-the-first-startup
      # - NEXTCLOUD_STARTUP_APPS=deck twofactor_totp tasks calendar contacts notes
      # This allows to add additional packages to the Nextcloud container permanently. Default is imagemagick but can be overwritten by modifying this value. See https://github.com/nextcloud/all-in-one#how-to-add-os-packages-permanently-to-the-nextcloud-container
      # - NEXTCLOUD_ADDITIONAL_APKS=imagemagick
      # This allows to add additional php extensions to the Nextcloud container permanently. Default is imagick but can be overwritten by modifying this value. See https://github.com/nextcloud/all-in-one#how-to-add-php-extensions-permanently-to-the-nextcloud-container
      # - NEXTCLOUD_ADDITIONAL_PHP_EXTENSIONS=imagick
      # This allows to enable the /dev/dri device in the Nextcloud container. Warning: this only works if the '/dev/dri' device is present on the host! If it should not exist on your host, don't set this to true as otherwise the Nextcloud container will fail to start! See https://github.com/nextcloud/all-in-one#how-to-enable-hardware-transcoding-for-nextcloud
      # - NEXTCLOUD_ENABLE_DRI_DEVICE=true
      # Setting this to true will keep Nextcloud apps that are disabled in the AIO interface and not uninstall them if they should be installed. See https://github.com/nextcloud/all-in-one#how-to-keep-disabled-apps
      # - NEXTCLOUD_KEEP_DISABLED_APPS=false
      # This allows to adjust the port that the talk container is using. See https://github.com/nextcloud/all-in-one#how-to-adjust-the-talk-port
      # - TALK_PORT=3478
      # Needs to be specified if the docker socket on the host is not located in the default '/var/run/docker.sock'. Otherwise mastercontainer updates will fail. For macos it needs to be '/var/run/docker.sock'
      # - WATCHTOWER_DOCKER_SOCKET_PATH=/var/run/docker.sock
    # # Uncomment the following line when using SELinux
    # security_opt: ["label:disable"]

  # Optional: Caddy reverse proxy. See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
  # You can find further examples here: https://github.com/nextcloud/all-in-one/discussions/588
  caddy:
    image: caddy:latest
    restart: always
    container_name: caddy
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./certs:/certs
      - ./config:/config
      - ./data:/data
      - ./sites:/srv
    network_mode: host

volumes:
  nextcloud_aio_mastercontainer:
    # Below line is not allowed to be changed as otherwise the built-in backup solution will not work
    name: nextcloud_aio_mastercontainer

# Optional: If you need ipv6, follow step 1 and 2 of https://github.com/nextcloud/all-in-one/blob/main/docker-ipv6-support.md first and then uncomment...
# Please make sure to uncomment also the networking lines of the mastercontainer above in order to actually create the network with docker-compose
networks:
  nextcloud-aio:
    # Next line is not allowed to be changed as otherwise the created network will not be used by the other containers of AIO
    name: nextcloud-aio
    # use next line if there is an existing network. Else, comment it and uncomment below.
    external: true
    # driver: bridge
    # enable_ipv6: true
    # ipam:
    #   driver: default
    #   config:
    #     - subnet: fd12:3456:789a:2::/64 # IPv6 subnet to use
```

#### Caddyfile

```properties
(tls_snippet) {
  tls {
    client_auth {
      mode require_and_verify
      trusted_ca_cert_file /certs/Absolute_Trust_Global_Root_CA_-_G2.crt
      trusted_ca_cert_file /certs/Absolute_Trust_ID_Assurance_-_G2.crt
      trusted_ca_cert_file /certs/Absolute_Trust_ID_Assurance_PKI.crt
      trusted_ca_cert_file /certs/LOBOCKI-PIEKARNIK-CA.crt
    }
  }
}

(header_snippet) {
  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    X-XSS-Protection "1; mode=block"
    X-Frame-Options "SAMEORIGIN"
    Referrer-Policy "strict-origin-when-cross-origin"
    Content-Security-Policy "upgrade-insecure-requests"
    -Server
    -X-Powered-By
  }
  tls lukasz.lobocki@googlemail.com
  log {
    output file /data/caddylog.json {
      roll_size 150MiB
      roll_keep 10
      roll_keep_for 42d
      roll_uncompressed
    }
  }
}

https://caddylog.lobocki.duckdns.org {
  import tls_snippet
  import header_snippet
  root * /srv/goaccess_caddy
  file_server {
    index caddylog.html
  }
  #basicauth {
  #  la_lukasz **[redacted]**
  #}
}

# Nextcloud. SSH:11022
https://lobocki.duckdns.org {
  # import tls_snippet
  import header_snippet
  reverse_proxy localhost:11000
}

https://paperless.lobocki.duckdns.org {
  import tls_snippet
  import header_snippet
  reverse_proxy localhost:8081
  encode gzip
}

https://pihole.lobocki.duckdns.org {
  import tls_snippet
  import header_snippet
  reverse_proxy 192.168.2.2:80
  redir / /admin{uri}
  encode gzip
}

https://dash.lobocki.duckdns.org {
  import tls_snippet
  import header_snippet
  reverse_proxy odroid.lan:3001
  #basicauth {
  #  la_lukasz **[redacted]**
  #}
  encode gzip
}
```

```bash
docker compose up -d
```

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
      "encrypt": true,
      "previews": true,
      "enable_sharing": false,
      "filesystem_check_changes": 1,
      "encoding_compatibility": false,
      "readonly": true
    },
    "applicable_users": [],
    "applicable_groups": []
  },
  {
    "mount_id": 3,
    "mount_point": "\/Consume",
    "storage": "\\OC\\Files\\Storage\\Local",
    "authentication_type": "null::null",
    "configuration": {
      "datadir": "\/home\/la_lukasz\/paperless-ngx\/consume"
    },
    "options": {
      "encrypt": true,
      "enable_sharing": false,
      "filesystem_check_changes": 1,
      "encoding_compatibility": false,
      "readonly": false,
      "previews": false
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

#### Caddy log retrieval

```bash
curl -s 'https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-ASN&license_key=**[redact]**&suffix=tar.gz' \
  --output - \
| sudo tar --wildcards --strip-components=1 --overwrite \
  -C ~/nextcloud-aio/data -xvzf - '*.mmdb'

curl -s 'https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=**[redact]**&suffix=tar.gz' \
  --output - \
| sudo tar --wildcards --strip-components=1 --overwrite \
  -C ~/nextcloud-aio/data -xvzf - '*.mmdb'
```

```bash
ssh la_lukasz@nuc11atk.lan \
'zcat $(ls -t ~/nextcloud-aio/data/caddylog*.gz | head -2) \
  | docker run --rm -i -e LANG=$LANG \
  -v /home/la_lukasz/nextcloud-aio/data:/input \
  -v /home/la_lukasz/nextcloud-aio/sites/goaccess_caddy:/output \
  allinurl/goaccess --log-format CADDY --exclude-ip=192.168.2.1 \
  --with-output-resolver --agent-list --tz="Europe/Berlin" \
  --enable-panel=VISITORS \
  --ignore-panel=REQUESTS \
  --ignore-panel=REQUESTS_STATIC \
  --ignore-panel=NOT_FOUND \
  --enable-panel=HOSTS \
  --enable-panel=OS \
  --enable-panel=BROWSERS \
  --ignore-panel=VISIT_TIMES \
  --enable-panel=VIRTUAL_HOSTS \
  --ignore-panel=REFERRERS \
  --ignore-panel=REFERRING_SITES \
  --ignore-panel=KEYPHRASES \
  --ignore-panel=STATUS_CODES \
  --ignore-panel=REMOTE_USER \
  --ignore-panel=CACHE_STATUS \
  --ignore-panel=GEO_LOCATION \
  --enable-panel=ASN \
  --ignore-panel=MIME_TYPE \
  --ignore-panel=TLS_TYPE \
  --no-query-string --unknowns-as-crawlers --max-items=9 --real-os \
  --geoip-database=/input/GeoLite2-Country.mmdb \
  --geoip-database=/input/GeoLite2-ASN.mmdb \
  --html-report-title="Caddylog" --output=/output/caddylog.html \
  /input/caddylog.json -'
```

#### Chown and chmod

```bash
sudo chown --recursive www-data:www-data \
  /mnt/btrfs/nextcloud \
&& sudo find /mnt/btrfs/nextcloud -type d -print0 \
  | xargs -0 sudo -u www-data chmod u=rwx,g=rx \
&& sudo find /mnt/btrfs/nextcloud -type f -print0 \
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
  php occ trashbin:cleanup --all-users \
; sudo docker exec --user www-data -it nextcloud-aio-nextcloud \
  php occ versions:cleanup
```

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

:information_source: Check [detox](https://linux.die.net/man/1/detox) command.

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

## 5. Setup _PiHole_ on _docker_ at _odroid_

### 5.1. Install

```bash
ip --color route | grep default
ip --color addr show
```

:information_source: Please note if `end0` is the interface.

#### Static IP

```bash
sudo nano /etc/network/interfaces.d/end0
```

```properties
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

#### docker-compose.yml

```yaml
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
      # - "67:67/udp" # Only required if using Pi-hole as DHCP server
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
      # Required if using Pi-hole as DHCP server, else not needed
      - NET_ADMIN
    restart: unless-stopped
```

```bash
docker compose up -d
```

## 6. Setup _Vaultwarden_ on _docker_ at _NUC11ATK_

### 6.1. Install

Use portainer stacks.

#### docker-compose.yml

```yml
name: vaultwarden
services:
  server:
    container_name: vaultwarden
    volumes:
      - /mnt/btrfs/vw-data/:/data/
    environment:
      - ADMIN_TOKEN=***[redacted]***
    restart: unless-stopped
    ports:
      - 8082:80
    image: vaultwarden/server:latest
```

## 7. Setup _smallstep_ CA PKI on _docker_ at _odroid_

:information_source: Check [this](https://smallstep.com/blog/everything-pki) out.

### 7.1. Install

```bash
docker run -it --name "smallstep-odroid-pki" \
  -v /home/la_lukasz/smallstep:/home/step \
  -p 9000:9000 \
  -e "DOCKER_STEPCA_INIT_NAME=odroid-pki" \
  -e "DOCKER_STEPCA_INIT_DNS_NAMES=localhost,odroid,odroid.lan" \
  -e "DOCKER_STEPCA_INIT_PROVISIONER_NAME=lukasz.lobocki@googlemail.com" \
  smallstep/step-ca \
2>&1 | tee -a step-ca.init
```

:information_source: Check [this](https://smallstep.com/docs/tutorials/intermediate-ca-new-ca/#the-medium-way) on swapping CA certs.

~/smallstep/config/defaults.json

```json
{
  "ca-url": "https://localhost:9000",
  "ca-config": "/home/step/config/ca.json",
  "fingerprint": "159289cc4715bebbd2f1f7156883580ce9de7162576140f2a4621b91858c7ddc",
  "root": "/home/step/certs/Absolute_Trust_Global_Root_CA_-_G2.crt"
}
```

~/smallstep/config/ca.json

```json
{
  "root": "/home/step/certs/Absolute_Trust_Global_Root_CA_-_G2.crt",
  "federatedRoots": null,
  "crt": "/home/step/certs/Absolute_Trust_ID_Assurance_PKI.crt",
  "key": "/home/step/secrets/Absolute_Trust_ID_Assurance_PKI_key",
  "address": ":9000",
  "insecureAddress": "",
  "dnsNames": [
    "localhost",
    "odroid",
    "odroid.lan"
  ],
  "logger": {
    "format": "text"
  },
  "db": {
    "type": "badgerv2",
    "dataSource": "/home/step/db",
    "badgerFileLoadingMode": ""
  },
  "authority": {
    "provisioners": [
      {
        "type": "JWK",
        "name": "lukasz.lobocki@googlemail.com",
        "key": {
          "use": "sig",
          "kty": "EC",
          "kid": "**[redacted]**",
          "crv": "P-256",
          "alg": "ES256",
          "x": "**[redacted]**",
          "y": "**[redacted]**"
        },
        "encryptedKey": "**[redacted]**",
        "claims": {
          "minTLSCertDuration": "5m",
          "maxTLSCertDuration": "8760h",
          "defaultTLSCertDuration": "720h",
          "disableRenewal": false,
          "minHostSSHCertDuration": "5m",
          "maxHostSSHCertDuration": "8760h",
          "minUserSSHCertDuration": "5m",
          "maxUserSSHCertDuration": "8760h",
          "enableSSHCA": true
        },
        "options": {
          "x509": {
            "templateFile": "templates/certs/x509/leaf.tpl",
            "templateData": {
              "OrganizationalUnit": "Sternicza"
            }
          }
        }
      }
    ]
  },
  "tls": {
    "cipherSuites": [
      "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
      "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
    ],
    "minVersion": 1.2,
    "maxVersion": 1.3,
    "renegotiation": false
  }
}
```

~/smallstep/templates/certs/x509/leaf.tpl

```json
{
  "subject": {{ toJson .Subject }},
  "sans": {{ toJson .SANs }},
{{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
  "keyUsage": ["keyEncipherment", "digitalSignature"],
{{- else }}
  "keyUsage": ["digitalSignature"],
{{- end }}
  "extKeyUsage": ["serverAuth", "clientAuth"]
}
```

### 7.2. Admining

On client

```bash
step ca bootstrap --ca-url=odroid:9000 \
  --fingerprint=159289cc4715bebbd2f1f7156883580ce9de7162576140f2a4621b91858c7ddc
```

```bash
step certificate install --all ~/.step/certs/root_ca.crt
```

```bash
step ca certificate lobocki.duckdns.org \
  lobocki.duckdns.org.crt lobocki.duckdns.org.key \
  --san lobocki.duckdns.org --san lukasz.lobocki@googlemail.com \
  --kty EC --curve P-256 --not-after 8760h \
  --ca-url=https://lobocki.duckdns.org:9000
```
