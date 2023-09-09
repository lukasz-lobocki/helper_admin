# FISH

## Functions

Copy those `*.fish` files over to `~/.config/fish/functions`.

## How to do different actions if it runs on Fish

Command `fish_greeting` is specific to fish.

```bash
fish_greeting > /dev/null 2>&1 \
  || echo "not fish"
fish_greeting > /dev/null 2>&1 \
  && echo "fish"
```

## Exportable environment variables

Issue following commands to update `~/.config/fish/fish_variables` with exportable environment variables.

### Colors

```bash
set -Ux EXA_COLORS 'da=38;5;12:gm=38;5;12:di=38;5;12;01:xx=36'
```

```bash
set -Ux JQ_COLORS "2;37:0;39:0;39:0;39:0;39:1;39:1;39:1;33"
```

### Github

```bash
set -Ux GH_USER 'lukasz-lobocki'
```

```bash
set -Ux GH_TOKEN 'ghp...'
```

### Borgbackup

Check [this](https://borgbackup.readthedocs.io/en/stable/faq.html?highlight=BORG_PASSCOMMAND#how-can-i-specify-the-encryption-passphrase-programmatically) and [this](https://borgbackup.readthedocs.io/en/stable/usage/key.html) files.

```bash
set -Ux BORG_PASSCOMMAND "cat $HOME/.borg-passphrase"
```

## Path

Issue to populate fish's PATH

```bash
fish_add_path -m \
  /usr/local/bin \
  /usr/bin \
  /home/lukasz/.local/bin \
  /bin \
  /usr/local/go/bin \
  /home/lukasz/.cargo/bin \
  /snap/bin
```
