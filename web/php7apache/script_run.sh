#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/log/apache
mkdir -p /home/webuser/www/public
mkdir -p /home/webuser/tmp/temp
chown -R www-data:www-data /home/webuser

NEWUSER=$(hostname | tr -d "_.-")
if [ ! -d /home/$NEWUSER ]; then
	useradd --no-create-home --home-dir /home/$NEWUSER --shell /bin/bash --gid $(id -g www-data) --non-unique --uid $(id -u www-data) $NEWUSER
	ln -s /home/webuser /home/$NEWUSER
fi

export APACHE_LOG_DIR=/home/webuser/log/apache
exec apache2-foreground
