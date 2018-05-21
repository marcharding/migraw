# Migraw

[![Build status](https://ci.appveyor.com/api/projects/status/github/marcharding/DellFanControl?svg=true)](https://ci.appveyor.com/project/MarcHarding/dellfancontrol)

## Introduction

Portable (web)development enviroments on windows as an lightweight alternative to docker.

## Usage

TODO

## Sample migraw.json (one Host)

```json
{
	"name": "example",
	"network": {
		"ip": "127.0.0.1",
		"host": "local.example.com"
	},
	"document_root": "web",
	"config": {
		"php": "7.1",
		"apache": true,
		"mysql": true,
		"mailhog": true
	},
	"exec": [
		"composer install"
	]
}
```

## Sample migraw.json (multiple hosts)

```json
{
	"name": "example",
	"network": {
		"ip": "127.0.0.1",
		"host": "local.example.com"
	},
	"virtual_document_root": "%0/web",
	"config": {
		"php": "7.1",
		"apache": true,
		"mysql": true,
		"mailhog": true
	},
	"exec": [
		"composer install"
	]
}
```