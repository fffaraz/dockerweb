#!/bin/bash
set -euxo pipefail

apt-get -yq update

apt-get -yq install git zip unzip # php5-mcrypt php5-json php5-mysql
apt-get -yq install libfreetype6-dev libicu-dev libpq-dev libjpeg62-turbo-dev libmcrypt-dev libpng-dev

# PHP Core Extensions
docker-php-ext-install -j$(nproc) iconv mcrypt zip
docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd
docker-php-ext-install -j$(nproc) gd intl mbstring pcntl pdo_mysql pdo_pgsql pgsql

#php5enmod mcrypt
#php5enmod json
a2enmod rewrite

mkdir -p /home/webuser/log/apache
mkdir -p /home/webuser/www/public
service apache2 restart

# Composer
cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
composer global require "laravel/installer"

# Site
cat > /etc/apache2/sites-available/000-laravel.conf <<'EOL'
<VirtualHost *:80>
        DocumentRoot /home/webuser/www/public
        ServerName localhost
        ServerAdmin webmaster@localhost
        <Directory />
                Options FollowSymLinks
                AllowOverride All
        </Directory>
        <Directory /home/webuser/www/>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                allow from all
        </Directory>
        LogLevel warn
        ErrorLog /home/webuser/log/apache/error.log
        CustomLog /home/webuser/log/apache/access.log combined
</VirtualHost>
EOL

/usr/sbin/a2dissite '*'
/usr/sbin/a2ensite 000-laravel
service apache2 restart

# Clean up
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/webuser
rm /script_init.sh
