# Migraw

## Introduction

Portable (web)development enviroments on osx as an lightweight alternative to docker/vagrant/etc.

## Requirements

- Homebrew installed
- Apple silicon / m1 mac

## Installation

Install with curl https://raw.githubusercontent.com/marcharding/migraw/osx/install.sh | sudo bash

## Usage

Just call `migraw` to see the possible options.

## Redirect ports

Since you can only bind ports < 1024 without using sudo, an alternative is to redirect port 80 and 443 to 8080 and 8443.

The following commands utilize pf to redirect these ports.

Create a new anchor for pf:

```bash
sudo cat > /etc/pf.anchors/migraw << EOL
    rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port 8080
    rdr pass inet proto tcp from any to any port 443 -> 127.0.0.1 port 8443
EOL
```

Create a config for our new anchor (so the default pf.conf ist not edited)

```bash
sudo cat > /etc/pf-migraw.conf << EOL
    rdr-anchor "migraw"
    load anchor "migraw" from "/etc/pf.anchors/migraw"
EOL
```

Manually load/test

```bash
sudo pfctl -ef /etc/pf-migraw.conf
```

Register a new launch daemon to automatically start the redirect pf script

```bash
sudo cat > /Library/LaunchDaemons/migraw.redirect.pfctl.plist << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- copied from /System/Library/LaunchDaemons/com.apple.pfctl.plist -->
<plist version="1.0">
	<dict>
		<key>Disabled</key>
		<false/>
		<key>Label</key>
		<string>migraw.redirect.pfctl.plist</string>
		<key>WorkingDirectory</key>
		<string>/var/run</string>
		<key>Program</key>
		<string>/sbin/pfctl</string>
		<key>ProgramArguments</key>
		<array>
			<string>pfctl</string>
			<string>-e</string>
			<string>-f</string>
			<string>/etc/pf-migraw.conf</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>
````

# sudo launchctl load -w /Library/LaunchDaemons/migraw.redirect.pfctl.plist

## Usage

Just call `migraw` to see the possible options.

## Sample migraw.yml configuration

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
p