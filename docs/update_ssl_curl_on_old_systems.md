# Upgrading OpenSSL, Curl and wget on Debian 6/7 or Ubuntu 8
First install dev dependencies

    sudo apt-get install libz-dev build-essential
 
Then get OpenSSL sources via https://www.openssl.org/source/ 
and Curl sources via https://curl.se/download.html 
possibly use a bridge FTP server like this (if you are not able at all to wget it due to tls v1.0 certificate)

    ftp -n -v ftp.xyz.domain << ENDFTP
    user USERNAME PASSWORD
    get openssl-1.1.1m.tar.gz
    get curl-7.81.0.tar.gz
    bye
    ENDFTP
    
## Build OpenSSL from source

    tar -xzf openssl-1.1.1m.tar.gz
    cd openssl-1.1.1m
    ./config --prefix=/usr zlib-dynamic --openssldir=/etc/ssl shared
    make
    sudo make install
    
## Build Curl from source

    sudo apt-get remove curl
    tar -xzf curl-7.81.0.tar.gz
    cd curl-7.81.0
    ./configure --disable-shared --with-openssl
    make
    sudo make install
    ln -s /usr/local/bin/curl /usr/bin/curl

## Upgrade wget with curl already upgraded

    sudo apt-get remove wget
    curl -O  http://ftp.gnu.org/gnu/wget/wget-1.21.tar.gz
    tar -xzf wget-1.21.tar.gz
    cd wget-1.21
    CFLAGS=-std=gnu99 ./configure --with-ssl=openssl --with-libssl-prefix=/usr/bin/openssl
    make
    sudo make install
    ln -s /usr/local/bin/wget /usr/bin/wget

## WARNING: Don't forget to update ca-certificates locally

    update-ca-certificates --fresh

In case of missing ones like this

    ERROR: cannot verify cache.ruby-lang.org's certificate, issued by ‘CN=GlobalSign Atlas R3 DV TLS CA H2 2021,O=GlobalSign nv-sa,C=BE’:
    Unable to locally verify the issuer's authority.
    To connect to cache.ruby-lang.org insecurely, use `--no-check-certificate'.

Download corresponding certificate, add it to `/etc/ssl/certs` and update ca-certificates

    wget https://raw.githubusercontent.com/rubygems/rubygems/master/lib/rubygems/ssl_certs/rubygems.org/GlobalSignRootCA_R3.pem
    cp GlobalSignRootCA_R3.pem /etc/ssl/certs/
    update-ca-certificates --fresh

    
## Check your versions and functionnality
    
    openssl version
    wget -V
    curl --version
    curl -v -s --tlsv1 https://www.ssllabs.com/ssltest 1>/dev/null
    
Last line should display something like

```
*   Trying 64.41.200.100:443...
* Connected to www.ssllabs.com (64.41.200.100) port 443 (#0)
* ALPN, offering http/1.1
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: none
} [5 bytes data]
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
} [512 bytes data]
* TLSv1.3 (IN), TLS handshake, Server hello (2):
{ [122 bytes data]
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
{ [25 bytes data]
* TLSv1.3 (IN), TLS handshake, Certificate (11):
{ [3239 bytes data]
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
{ [264 bytes data]
* TLSv1.3 (IN), TLS handshake, Finished (20):
{ [36 bytes data]
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
} [1 bytes data]
* TLSv1.3 (OUT), TLS handshake, Finished (20):
} [36 bytes data]
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
```