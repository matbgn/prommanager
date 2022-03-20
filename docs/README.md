# Prometheus Manager

## Description
Manager to install, update, init Prometheus and node_exporter.

## Installation
    curl -OL https://raw.githubusercontent.com/matbgn/prometheus-manager/master/prometheus-manager.sh
    chmod +x prometheus-manager.sh
    ./prometheus-manager.sh -h

## Usage
Get helper by running this command:

    sudo ./prometheus-manager.sh --help

## OS Architecture
Specify which one you want with (default is amd64):

    sudo ./prometheus-manager.sh --arch arm64 [--<flags>]

## Pull latest release versions
Get info with:

    sudo ./prometheus-manager.sh --versions --all

Then let the retrieved versions stored in .env file do the job for all:

    sudo ./prometheus-manager.sh --install --node --prometheus

Equivalent to:

    sudo ./prometheus-manager.sh --install --all

Or specify which version you will install by:

    sudo ./prometheus-manager.sh --install -N 1.1.2 -P 2.2.7

## Get actual services status

    sudo ./prometheus-manager.sh --status --all

## Miscellaneous

- [Update OpenSSL and Curl on old systems](update_ssl_curl_on_old_systems.md)
