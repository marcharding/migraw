# Migraw

## Introduction

Portable (web)development enviroments on wsl/ubuntu 18.04 as an lightweight alternative to docker/vagrant/etc.

## Installation

Install with curl https://raw.githubusercontent.com/marcharding/migraw/master/install.sh | sudo bash

After that just add the migraw (default is /opt/migraw) folder to your path.

When using WSL, you may want to tweak it a bit.

See https://docs.microsoft.com/en-us/windows/wsl/install-win10 for information regarding wsl.

Add this to `/etc/wsl.conf`

```conf
# Enable extra metadata options by default
[automount]
enabled = true
root = /mnt/
options = "metadata"
mountFsTab = false
```

See https://docs.microsoft.com/en-us/windows/wsl/wsl-config#set-wsl-launch-settings.

Furthermore it is a good idea to exlude some processes from windows defender to work around i/o limitations within wsl.

See the following issues for further information about that:
- https://github.com/Microsoft/WSL/issues/1932
- https://gist.github.com/dayne/313981bc3ee6dbf8ee57eb3d58aa1dc0#file-1-wsl-defender-fix-md

I just excluded the whole wsl folder and the most common processes:

```ps
$win_user = "ipc" # Your windows username
$linux_user = "ipc" # Your wsl username
$package = "CanonicalGroupLimited.Ubuntu18.04onWindows_79rhkp1fndgsc"
$base_path = "C:\Users\" + $win_user + "\AppData\Local\Packages\" + $package + "\LocalState\rootfs"
Add-MpPreference -ExclusionPath ($base_path)

@("apache2", "mysqld", "node", "php", "php5.6", "php7.0", "php7.1", "php7.2", "php7.3", "ruby")
$dirs | ForEach { Add-MpPreference -ExclusionProcess ($_) }
```

## Usage

Just call `migraw` to see the possible options.

## Sample migraw.yaml configuration

Each project needs a yaml configuration file which looks like this (should be self explanatory)

```yaml
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