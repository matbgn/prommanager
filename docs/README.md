<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable-next-line -->
<h2 align="center">
  <br>
  <p align="center"><img width=35% alt="" src="https://raw.githubusercontent.com/matbgn/prometheus-manager/master/docs/img/prometheus-manager_logo.svg"></p>
Prometheus Manager
</h2>

<p align="center">
   <a href="https://github.com/matbgn/prometheus-manager/releases">
   <img alt="Release" src="https://img.shields.io/github/v/release/matbgn/prometheus-manager">
   <a href="https://github.com/matbgn/prometheus-manager/issues">
   <img alt="GitHub issues" src="https://img.shields.io/github/issues/matbgn/prometheus-manager?style=flat-square&logo=github&logoColor=white">
   <a href="https://github.com/matbgn/prometheus-manager/blob/master/LICENSE.md">
   <img alt="License" src="https://img.shields.io/github/license/matbgn/prometheus-manager">
   <a href="https://github.com/agarrharr/awesome-cli-apps#devops">
   <img alt="Awesome" src="https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg">
</p>

<p align="center">
    <img alt="Supports arm64 Architecture" src="https://img.shields.io/badge/arm64-yes-green.svg">
    <img alt="Supports amd64 Architecture" src="https://img.shields.io/badge/amd64-yes-green.svg">
</p>

<p align="center">
  <a href="#supported-services">Supported Services</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#miscellaneous">Miscellaneous</a> •
  <a href="#acknowledgments">Acknowledgments</a>
</p>

---


## Description
**Prometheus Manager** is a tool to install, update and execute Prometheus and different exporters automatically.

## Supported services

- *Prometheus*
- *Node Exporter*
- *Blackbox Exporter*
- *Alertmanager*
- *Communication services such as:*
  - *Emails*
  - *Microsoft Teams*
  - *Telegram*
  - *Slack*
  - *And many more thanks to [PingMe CLI](https://pingme.lmno.pk/#/services) Integration*

## Installation
    curl -OL https://raw.githubusercontent.com/matbgn/prometheus-manager/master/prometheus-manager.sh
    chmod +x prometheus-manager.sh
    ./prometheus-manager.sh -h

## Usage
Get helper by running this command:

    sudo ./prometheus-manager.sh --help

### OS Architecture
Specify which one you want with (default is amd64):

    sudo ./prometheus-manager.sh --arch arm64 [--<flags>]

### Pull latest release versions
Get info with:

    sudo ./prometheus-manager.sh --versions --all

Then let the retrieved versions stored in .env file do the job for all:

    sudo ./prometheus-manager.sh --install --node --prometheus

Equivalent to:

    sudo ./prometheus-manager.sh --install --all

Or specify which version you will install by:

    sudo ./prometheus-manager.sh --install -N 1.1.2 -P 2.2.7

### Get actual services status

    sudo ./prometheus-manager.sh --status --all

## Configuration

All the communications services have corresponding environment variables associated with it. You
have to provide those within an .env file (see .env.example).

View the [PingMe CLI Documentation Page](https://pingme.lmno.pk/#/services) for more
details.

## Miscellaneous

- [Update OpenSSL and Curl on old systems](update_ssl_curl_on_old_systems.md)

## Acknowledgments

This project is based on those amazing projects:
- [Prometheus](https://github.com/prometheus/) (Apache License 2.0)
- [shdotenv](https://github.com/ko1nksm/shdotenv) (MIT License)
- [shell2http](https://github.com/msoap/shell2http) (MIT License)
- [PingMe CLI](https://github.com/nikoksr/notify) (MIT License)

