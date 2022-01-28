# Migraw

## Introduction

Portable (web)development enviroments on wsl2 with ubuntu/debian as an lightweight alternative to docker/vagrant/etc.

## Installation

Just download the script to a folder and add a symlink to you path for easier access.

```bash
$A_FOLDER_YOU_LIKE=$HOME/migraw
mkdir -p $A_FOLDER_YOU_LIKE
sudo curl -s -H 'Cache-Control: no-cache' "https://raw.githubusercontent.com/marcharding/migraw/main-dpkg/migraw.sh" --output "$A_FOLDER_YOU_LIKE/migraw.sh"
sudo chmod +x $A_FOLDER_YOU_LIKE/migraw.sh
sudo ln -rsf $A_FOLDER_YOU_LIKE/migraw.sh $HOME/.bin/migraw
```

When using WSL2, you may want to tweak it a bit.

See https://docs.microsoft.com/en-us/windows/wsl/install for information regarding wsl.

Add this to `%UserProfile%/.wslconfig`:

```conf
[wsl2]
memory=4GB
processors=4
generateResolvConf = true
```

See https://docs.microsoft.com/en-us/windows/wsl/wsl-config#set-wsl-launch-settings for further info.

Restart WSL2 after this by `Restart-Service LxssManager` in an elevated powershell prompt.

Fix connectivity by adding a fixed dns:

```bash
sudo bash -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
```

And by disableing ipv6

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

## Requirements

### Add needed repositories

#### PHP

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
```

#### Blackfire

```bash
wget -q -O - https://packages.blackfire.io/gpg.key | sudo apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list
sudo apt update
```

### Install needed packages globally

```bash
apt-get install authbind socat imagemagick
```

To forward ports 8080 and 8443 to 80 and 443

```bash
sudo touch /etc/authbind/byport/{80,443}
sudo chgrp $USER /etc/authbind/byport/{80,443}
sudo chmod 550 /etc/authbind/byport/{80,443}
```

Imagemagick needs to be installed on the host machine globally, since the "installed" version does not respect all available enviroment variables.

To enable PDF renderings we need to relax some recurity restrictions (see https://stackoverflow.com/a/69535567):

```bash
sudo sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml
```

Furthermore it is a good idea to exlude some processes from windows defender to work around misc. i/o limitations within wsl and windows.

See the following issues for further information about that (these also apply to wsl2 and windows in general):
- https://github.com/Microsoft/WSL/issues/1932
- https://gist.github.com/dayne/313981bc3ee6dbf8ee57eb3d58aa1dc0#file-1-wsl-defender-fix-md

I just excluded the whole wsl2 network mount and the most common processes.

### Finally install all migraw packages

```bash
migraw install
```

## Usage

Just call `migraw` to see the possible options.

### Sample migraw.yml configuration

Each project needs a yaml configuration file which looks like this (should be self explanatory)

```yml
name: local-develop
network:
	ip: 127.0.0.1
	host: local.local-develop.net
document_root: web
config:
	php: 7.2
	apache: true
	mysql: true
	mailhog: true
```
