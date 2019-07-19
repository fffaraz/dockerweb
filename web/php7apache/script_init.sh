#!/bin/bash
set -euxo pipefail

#sed -ri -e 's!/var/www/html!/home/webuser/www/public!g' /etc/apache2/sites-available/*.conf
#sed -ri -e 's!/var/www!/home/webuser/www!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

apt-get -yq update
apt-get -yq install git nano zip unzip wget libfreetype6-dev libjpeg62-turbo-dev libpng-dev zip unzip
apt-get -yq install libicu-dev mysql-client libpq-dev libmcrypt-dev libssl-dev libsqlite3-dev
#apt-get -yq install postgresql-client

docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd

#docker-php-ext-install -j$(nproc) mcrypt
docker-php-ext-install -j$(nproc) mysqli tokenizer gd intl iconv mbstring pcntl pdo pdo_mysql pdo_pgsql pdo_sqlite pgsql zip opcache

a2enmod rewrite

rm -rf /var/www/html
ln -s /home/webuser/www/public /var/www/html

useradd --no-create-home --home-dir /home/webuser --shell /bin/bash --gid $(id -g www-data) --non-unique --uid $(id -u www-data) webuser

# Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Laravel
composer global require "laravel/installer"

# Site
cat > /etc/apache2/sites-available/000-laravel.conf <<'EOL'
#ServerName localhost
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /home/webuser/www/public
        <Directory />
                Options FollowSymLinks
                AllowOverride All
        </Directory>
        <Directory /home/webuser/www/>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                Allow from all
        </Directory>
        LogLevel warn
        ErrorLog /home/webuser/log/apache/error.log
        CustomLog /home/webuser/log/apache/access.log combined
</VirtualHost>
EOL

cat >> /etc/apache2/conf-available/docker-php.conf <<'EOL'
<Directory /home/webuser/www/>
        #Options -Indexes
        AllowOverride All
        Options Indexes FollowSymLinks
        #AllowOverride None
        Require all granted
</Directory>
EOL

cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini
echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/memory-limit.ini
echo "max_execution_time=0" > $PHP_INI_DIR/conf.d/max-execution-time.ini
echo "upload_max_filesize=1024M" > $PHP_INI_DIR/conf.d/upload.ini
echo "post_max_size=1024M" >> $PHP_INI_DIR/conf.d/upload.ini

/usr/sbin/a2dissite '*'
/usr/sbin/a2ensite 000-laravel

cat > /etc/profile.d/aliases.sh <<'EOL'
alias ll="ls -alh"
EOL

cat > /etc/profile.d/envvars.sh <<'EOL'
export TERM=xterm
export TEMP=/home/webuser/tmp/temp
export COMPOSER_HOME=/home/webuser/.composer
export PS1='\u@\H:\w\$ '
EOL

cat > /etc/profile.d/path.sh <<'EOL'
export PATH=$PATH:/home/webuser/.composer/vendor/bin
export PATH=$PATH:/home/webuser/.npm-global/bin
export PATH=$PATH:/home/webuser/spark-installer
EOL
source /etc/profile.d/path.sh

rm -rf /var/www/html
ln -s /home/webuser/www/public /var/www/html

# Clean up
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm /script_init.sh
