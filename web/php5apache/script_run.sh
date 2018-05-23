#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/log/apache
mkdir -p /home/webuser/www/public
chown -R www-data:www-data /home/webuser

export PATH=$PATH:$HOME/.composer/vendor/bin

exec apache2-foreground
