#!/bin/bash

mkdir -p /home/webuser/www/public

rm -rf /var/www/html
ln -s /home/webuser/www/public /usr/local/apache2/htdocs

chown -R webuser:webuser /home/webuser

cd /usr/local/apache2/htdocs
exec httpd-foreground
