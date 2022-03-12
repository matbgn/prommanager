# Prometheus Manager

## Description
Manager to install, update, init Prometheus and node_exporter.

## Installation
    wget https://raw.githubusercontent.com/matbgn/prometheus-manager/master/prometheus-manager.sh
        OR
    curl -OL https://raw.githubusercontent.com/matbgn/prometheus-manager/master/prometheus-manager.sh
    chmod +x prometheus-manager.sh
    ./prometheus-manager.sh -V

## Usage
Get helper by running this command:

    sudo ./prometheus-manager.sh -h

## OS Architecture
Specify which one you want with (default is amd64):

    sudo ./prometheus-manager.sh --arch arm64

## Pull latest release versions
Get info with:

    sudo ./prometheus-manager.sh -V

Then let the retrieved versions stored in .env file do the job for all:

    sudo ./prometheus-manager.sh --install --node --prom

Equivalent to:

    sudo ./prometheus-manager.sh --install --all

Or specify which version you will install by:

    sudo ./prometheus-manager.sh --install -N 1.1.2 -P 2.2.7

## Get actual services status

    sudo ./prometheus-manager.sh -s

## Miscellaneous

- [Update OpenSSL and Curl on old systems](update_ssl_curl_on_old_systems.md)
