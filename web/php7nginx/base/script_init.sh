#!/bin/bash
set -euxo pipefail

NGINX_VERSION=1.11.7
PHP_VERSION=7.1.0

NGINX_URL="https://nginx.org/en/download.html"
#RUNTIME_DEPS="libpcre3"
BUILD_DEPS="build-essential gcc g++ make"
NPROC=$(($(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)+1))

# Requirements
addgroup webuser
adduser --home /home/webuser --shell /bin/bash --no-create-home --gecos "" --ingroup webuser --disabled-password webuser

export DEBIAN_FRONTEND=noninteractive
apt-get -yq update < /dev/null
apt-get -yq upgrade < /dev/null
apt-get -yq install bash ca-certificates curl git mysql-client nano tree wget zip unzip xz-utils < /dev/null # perl python nodejs logrotate
apt-get -yq install openssl openssh-client openssh-sftp-server dropbear # openssh
apt-get -yq install $BUILD_DEPS zlib1g-dev libpcre3-dev libssl-dev libxslt1-dev libgd2-xpm-dev libperl-dev libbz2-dev libfreetype6-dev libjpeg-turbo8-dev libmcrypt-dev libpng12-dev libxml2-dev libcurl4-gnutls-dev < /dev/null
# libmysqlclient-dev bison libcurl4-openssl-dev libjpeg-dev libpspell-dev librecode-dev
#apt-get -yq build-dep nginx php7 < /dev/null
#pear install pear/PHP_Archive
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf
ldconfig
mkdir -p /opt
cd /opt

# Install SSH
#ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
#ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
#ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
#ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
#mkdir -p /etc/dropbear
#dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
#dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
#dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key

# Install NGINX
# https://ngxpagespeed.com/install
function version_sort() {
	sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4 -g
}
function version_older_than() {
	local test_version="$1"
	local compare_to="$2"
	local older_version=$(echo $@ | tr ' ' '\n' | version_sort | head -n 1)
	test "$older_version" != "$compare_to"
}

cd /opt
versions_available=$(curl -sS --fail "$NGINX_URL" | grep -o '/download/nginx-[0-9.]*[.]tar[.]gz' | sed -e 's~^/download/nginx-~~' -e 's~\.tar\.gz$~~')
latest_version=$(echo "$versions_available" | version_sort  | tail -n 1)
if version_older_than "$latest_version" "$NGINX_VERSION"; then
	echo "Expected the latest version of nginx to be at least $NGINX_VERSION but found $latest_version"
	exit 1
fi
NGINX_VERSION=$latest_version

wget -q http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar -xzf nginx-$NGINX_VERSION.tar.gz
rm nginx-$NGINX_VERSION.tar.gz
cd nginx-$NGINX_VERSION
./configure \
--prefix=/opt/nginx \
--error-log-path=/home/webuser/log/nginx/error.log \
--http-log-path=/home/webuser/log/nginx/access.log \
--http-client-body-temp-path=/home/webuser/tmp/nginx/client \
--http-proxy-temp-path=/home/webuser/tmp/nginx/proxy \
--http-fastcgi-temp-path=/home/webuser/tmp/nginx/fastcgi \
--http-uwsgi-temp-path=/home/webuser/tmp/nginx/uwsgi \
--http-scgi-temp-path=/home/webuser/tmp/nginx/scgi \
--user=webuser \
--group=webuser \
--without-select_module \
--without-poll_module \
--without-http_gzip_module \
--without-http_proxy_module \
--with-http_realip_module

make -j${NPROC}
make install
cd /opt
rm -rf nginx-$NGINX_VERSION

# TODO: https://github.com/pagespeed/ngx_pagespeed
# https://developers.google.com/speed/pagespeed/module/configuration
# https://developers.google.com/speed/pagespeed/module/build_ngx_pagespeed_from_source
# https://www.digitalocean.com/community/tutorials/how-to-add-ngx_pagespeed-to-nginx-on-ubuntu-14-04

# Install PHP7

latest_version=$(curl -sS --fail "http://php.net/releases/index.php?json&version=7&max=1" | grep -o 'php-[0-9.]*[.]tar[.]gz' | sed -e 's~^php-~~' -e 's~\.tar\.gz$~~')
if version_older_than "$latest_version" "$PHP_VERSION"; then
	echo "Expected the latest version of php to be at least $PHP_VERSION but found $latest_version"
	exit 1
fi
PHP_VERSION=$latest_version

cd /opt
wget -qO php-$PHP_VERSION.tar.xz http://php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror
tar -Jxf php-$PHP_VERSION.tar.xz
rm php-$PHP_VERSION.tar.xz
cd php-$PHP_VERSION
# --enable-compile-warnings=no
./configure \
--prefix=/opt/php \
--with-config-file-path=/opt/php/conf \
--with-config-file-scan-dir=/opt/php/conf/php.ini.d \
--enable-bcmath \
--enable-calendar \
--enable-dba \
--enable-exif \
--enable-fpm \
--enable-ftp \
--enable-gd-jis-conv \
--enable-gd-native-ttf \
--enable-mbstring \
--enable-mysqlnd \
--enable-opcache \
--enable-pcntl \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--enable-wddx \
--enable-zip \
--disable-cgi \
--disable-debug \
--disable-phpdbg \
--with-bz2 \
--with-curl \
--with-fpm-group=webuser \
--with-fpm-user=webuser \
--with-gd \
--with-freetype-dir=/usr/include/ \
--with-png-dir=/usr/include/ \
--with-jpeg-dir=/usr/include/ \
--with-mcrypt \
--with-mhash \
--with-mysqli=mysqlnd \
--with-openssl \
--with-pdo-mysql=mysqlnd \
--with-zlib
make -j${NPROC}
make install
make clean
cd /opt
rm -rf php-$PHP_VERSION
rm -rf /opt/php/include
rm -rf /opt/php/php

# Clean up
apt-get purge -yq --auto-remove $BUILD_DEPS
apt-get -yq autoremove < /dev/null
apt-get -yq autoclean < /dev/null
sync

rm -rf /var/lib/apt/lists/*
rm -rf /var/lib/apt
rm -rf /var/cache/apt

rm -rf /home/webuser
rm -rf /var/tmp/*
rm -rf /tmp/*

rm /script_init.sh
exit 0
