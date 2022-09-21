# Migraw

## Introduction

Portable (web)development enviroments on macOS as an lightweight alternative to docker/vagrant/etc.

## Requirements

- Homebrew
- Apple silicon / m1 mac

## Installation

### Homebrew

https://brew.sh/

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Powerlevel10k (not required but ***highly recommended***):

https://github.com/romkatv/powerlevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
```

### Migraw

Just install with this one liner oder manually place the script in your path.

```bash
curl https://raw.githubusercontent.com/marcharding/migraw/macos/install.sh | bash
```

Call `migraw install` to install all migraw dependencies.

Execute `mkcert -install` to enable local ssl certificates.

## Usage

Enter `migraw` to see the possible options.

## Sample migraw.yml configuration

Each project needs a yaml configuration file which looks like this
(should be self explanatory)

```yml
name: local-develop
network:
    ip: 127.0.0.1
    host: local.local-develop.net
document_root: web
config:
    php: 8.1
    apache: true
    mysql: true
    mailhog: true
```
