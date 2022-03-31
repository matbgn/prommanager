<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable-next-line -->
<h2 align="center">
  <br>
  <p align="center"><img width=35% alt="" src="https://raw.githubusercontent.com/matbgn/prommanager/master/docs/img/prommanager_logo.svg"></p>
PromManager for Prometheus
</h2>

<p align="center">
   <a href="https://github.com/matbgn/prommanager/releases">
   <img alt="Release" src="https://img.shields.io/github/v/release/matbgn/prommanager">
   <a href="https://github.com/matbgn/prommanager/issues">
   <img alt="GitHub issues" src="https://img.shields.io/github/issues/matbgn/prommanager?style=flat-square&logo=github&logoColor=white">
   <a href="https://github.com/matbgn/prommanager/blob/master/LICENSE.md">
   <img alt="License" src="https://img.shields.io/github/license/matbgn/prommanager">
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
**PromManager** is a [KISS](https://en.wikipedia.org/wiki/KISS_principle) tool to set up, automatically update and execute Prometheus and related services with CLI on Linux servers which could be then interfaced with a Grafana Dashboard.

The main advantage is to facilitate maintenance trough multiple servers.

PromManager does not claim to allow all possible configurations with prometheus' ecosystem, but remains a good starting point for a simple and quick deployment.

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
    curl -OL https://raw.githubusercontent.com/matbgn/prommanager/master/prommanager
    chmod +x prommanager
    ./prommanager -h

## Usage
Get helper by running this command:

    sudo ./prommanager --help

### OS Architecture
Specify which one you want with (default is amd64):

    sudo ./prommanager --arch arm64 [--<flags>]

### Pull latest release versions
Get info with:

    sudo ./prommanager --versions --all

Then let the retrieved versions stored in .env file do the job for all:

    sudo ./prommanager --install --node --prometheus

Equivalent to:

    sudo ./prommanager --install --all

Or specify which version you will install by:

    sudo ./prommanager --install -N 1.1.2 -P 2.2.7

### Get actual services status

    sudo ./prommanager --status --all

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

