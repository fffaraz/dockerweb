#!/bin/bash
set -euxo pipefail

sed -ri -e 's!/var/www/html!/home/webuser/www/public!g' /etc/apache2/sites-available/*.conf
sed -ri -e 's!/var/www!/home/webuser/www!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

apt-get -yq update
apt-get -yq install git nano zip unzip wget libfreetype6-dev libjpeg62-turbo-dev libpng-dev

docker-php-ext-install -j$(nproc) iconv
docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-install -j$(nproc) gd

a2enmod rewrite

rm -rf /var/www/html
ln -s /home/webuser/www/public /var/www/html

# Clean up
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/webuser
rm /script_init.sh
