# UBUNTU POST-INSTALL

## Bigger font on login screen

```bash
sudo touch /usr/share/glib-2.0/schemas/93_hidpi.gschema.override
```

```bash
sudo nano /usr/share/glib-2.0/schemas/93_hidpi.gschema.override
```

```bash
[org.gnome.desktop.interface]
scaling-factor=2
```

```bash
sudo glib-compile-schemas /usr/share/glib-2.0/schemas
```

## Clean software stores

```bash
snap-store --quit && sudo snap refresh snap-store
```

```bash
sudo apt autoclean && sudo apt clean && sudo apt autoremove
```

## Microcontroller

```bash
pip3 install --upgrade esptool
```

```bash
pip3 install --upgrade rshell
```

## Other

### alias

Check [setup_bash_aliases](https://gist.github.com/lukasz-lobocki/706e2d53d86a0ba8085aed76dc07049b#file-setup_bash_aliases-sh) page.

`echo ${PATH}` --> `/home/lukasz/helper:/home/lukasz/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/snap/bin`

### ssh background

Check [sshbg](https://github.com/fboender/sshbg) and check out this [script](https://gist.github.com/lukasz-lobocki/706e2d53d86a0ba8085aed76dc07049b#file-setup_sshbg-sh)  page.

### ssh-agent

Check this [script](https://gist.github.com/lukasz-lobocki/706e2d53d86a0ba8085aed76dc07049b#file-setup_bashrc-sh) and [ssh-agent](https://gist.github.com/darrenpmeyer/e7ad217d929f87a7b7052b3282d1b24c) page.
