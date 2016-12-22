#!/bin/bash
set -euxo pipefail

groupadd -o -g 33 webuser
useradd -o -u 33 -g webuser webuser

apt-get update
apt-get -yq install nano wget

apt-get -yq install libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev
docker-php-ext-install -j$(nproc) iconv mcrypt
docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-install -j$(nproc) gd

# https://medium.com/dev-tricks/apache-and-php-on-docker-44faef716150
# /etc/apache2/envvars
# APACHE_RUN_USER
# APACHE_RUN_GROUP
# APACHE_LOG_DIR

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#apt-get clean
#rm -rf /var/cache/apt/*

rm /script_init.sh

# <IfModule mod_fcgid.c>
#    FcgidMaxRequestLen 1073741824
#    IdleTimeout 300
#    BusyTimeout 300
#    ProcessLifeTime 7200
#    IPCConnectTimeout 300
#    IPCCommTimeout 7200
# </IfModule>
