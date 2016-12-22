#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/www/public

rm -rf /var/www/html
ln -s /home/webuser/www/public /var/www/html

chown -R webuser:webuser /home/webuser

cd /var/www/html
exec apache2-foreground
