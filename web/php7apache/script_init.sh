#!/bin/bash
set -euxo pipefail

sed -ri -e 's!/var/www/html!/home/webuser/www/public!g' /etc/apache2/sites-available/*.conf
sed -ri -e 's!/var/www!/home/webuser/www!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

apt-get -yq update
apt-get -yq install git nano zip unzip wget libfreetype6-dev libjpeg62-turbo-dev libpng-dev zip unzip
apt-get -yq install libicu-dev mysql-client libpq-dev libmcrypt-dev libssl-dev libsqlite3-dev
#apt-get -yq install postgresql-client

docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd

#docker-php-ext-install -j$(nproc) mcrypt
docker-php-ext-install -j$(nproc) tokenizer gd intl iconv mbstring pcntl pdo pdo_mysql pdo_pgsql pdo_sqlite pgsql zip opcache

a2enmod rewrite

rm -rf /var/www/html
ln -s /home/webuser/www/public /var/www/html

useradd --no-create-home --home-dir /home/webuser --shell /bin/bash --gid $(id -g www-data) --non-unique --uid $(id -u www-data) webuser

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer
mv composer.phar /usr/local/bin/composer

# Clean up
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm /script_init.sh
