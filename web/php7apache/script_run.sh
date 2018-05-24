#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/log/apache
mkdir -p /home/webuser/www/public
chown -R www-data:www-data /home/webuser

export APACHE_LOG_DIR=/home/webuser/log/apache
exec apache2-foreground
