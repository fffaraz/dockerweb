#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/log/apache
mkdir -p /home/webuser/www/public
chown -R www-data:www-data /home/webuser

rm -rf /var/www/html
ln -s /home/webuser/www/public /var/www/html

exec apache2-foreground
