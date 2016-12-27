#!/bin/bash
set -euxo pipefail

NGINX_VERSION=1.11.7
NGINX_URL="https://nginx.org/en/download.html"
#RUNTIME_DEPS="libssl1.0.0 libxslt1.1 libpcre++ libgd3 libxpm4 libgeoip1"
BUILD_DEPS="build-essential gcc g++ make"
NPROC=$(($(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)+1))

# Requirements
addgroup webuser
adduser --home /home/webuser --shell /bin/bash --no-create-home --gecos "" --ingroup webuser --disabled-password webuser

export DEBIAN_FRONTEND=noninteractive
apt-get -yq update < /dev/null
apt-get -yq upgrade < /dev/null
apt-get -yq install bash curl wget unzip < /dev/null # logrotate
apt-get -yq install libssl-dev libxslt1-dev libpcre3-dev libgd2-xpm-dev libgeoip-dev
apt-get -yq install $BUILD_DEPS zlib1g-dev libpcre3 openssl libxml2-dev libgoogle-perftools-dev libperl-dev < /dev/null
#apt-get -yq build-dep nginx < /dev/null
echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf
ldconfig
mkdir -p /opt
cd /opt

# GeoIP
mkdir /opt/nginx
wget -qO /opt/nginx/GeoIP.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip /opt/nginx/GeoIP.dat.gz

# Nginx virtual host traffic status module
cd /opt
wget -q https://github.com/vozlt/nginx-module-vts/archive/master.zip
unzip master.zip
rm master.zip

# ngx_pagespeed
cd /opt
wget -q https://github.com/pagespeed/ngx_pagespeed/archive/latest-beta.zip
unzip latest-beta.zip
rm latest-beta.zip
cd ngx_pagespeed-latest-beta/
psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget -q ${psol_url}
tar -xzf $(basename ${psol_url})

# NAXSI is an open-source, high performance, low rules maintenance WAF for NGINX
# http://www.bluemind.org/linux-nginx-waf-reverse-proxy-for-wordpress-running-apache/
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-naxsi-on-ubuntu-14-04
cd /opt
wget -q https://github.com/nbs-system/naxsi/archive/master.zip
unzip master.zip
rm master.zip

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
sed -i -e 's/"Server: nginx"/"Server: Faraz"/g' src/http/ngx_http_header_filter_module.c
sed -i -e 's/"\\x84\\xaa\\x63\\x55\\xe7"/"\\x84\\xc2\\x3b\\x07\\xef"/g' src/http/v2/ngx_http_v2_filter_module.c
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
--with-threads \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-http_geoip_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--add-module=/opt/nginx-module-vts-master \
--add-module=/opt/ngx_pagespeed-latest-beta
#--add-module=/opt/naxsi-master/naxsi_src #put naxsi first in your ./configure
#--with-ngx_http_status_module

make -j${NPROC}
make install
cd /opt
rm -rf nginx-$NGINX_VERSION
rm -rf nginx-module-vts-master
rm -rf ngx_pagespeed-latest-beta
rm -rf naxsi-master

# Install letsencrypt
cd /opt
wget -q https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
/opt/certbot-auto --non-interactive || true

# Default ssl cert
mkdir -p /opt/nginx/conf/cert
openssl req -x509 -nodes -sha256 -days 730 -newkey rsa:4096 \
-keyout /opt/nginx/conf/cert/cert.key -out /opt/nginx/conf/cert/cert.crt \
-subj "/"
# -subj "/subjectAltName=DNS:yoursite.com,DNS:www.yoursite.com"
# -subj "/CN=MyCertificate/subjectAltName=DNS.1=*.com,DNS.2=*.ir"
# -subj "/C=US/ST=New York/L=New York City/O=Company/OU=Department/CN=MyCertificate/emailAddress=ssl@example.com/subjectAltName=DNS.1=*"
openssl dhparam -out /opt/nginx/conf/cert/dhparam.pem 2048 # -5 4096

# Clean up
apt-get purge -yq --auto-remove $BUILD_DEPS
apt-get -yq autoremove < /dev/null
apt-get -yq autoclean < /dev/null
rm -rf /var/lib/apt/lists/*
rm -rf /var/tmp/*
rm -rf /tmp/*
rm /script_init.sh
exit 0
