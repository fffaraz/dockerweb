#!/bin/bash

echo "<html><body><h1>It works!</h1></body></html>" > /home/webuser/www/public/index.html

if [ -z "${PHPMYADMIN:+x}" ]; then
	ln -s /opt/phpMyAdmin /home/webuser/www/public/pma
else
	ln -s /opt/phpMyAdmin /home/webuser/www/public/$PHPMYADMIN
fi

if [ -z "${PHPSTATUS:+x}" ]; then
	ln -s /opt/status /home/webuser/www/public/status
else
	ln -s /opt/status /home/webuser/www/public/$PHPSTATUS
fi

echo $MYSQL_ROOT_PASSWORD > /opt/mysql_root_password.txt

sed -i -e "s/__CaptchaPublic__/${CaptchaPublic}/" /opt/phpMyAdmin/config.inc.php
sed -i -e "s/__CaptchaPrivate__/${CaptchaPrivate}/" /opt/phpMyAdmin/config.inc.php
sed -i -e "s/__MYSQLSERVER__/${MYSQL_SERVER}/" /opt/phpMyAdmin/config.inc.php
sed -i -e "s/__MYSQLSERVER__/${MYSQL_SERVER}/" /opt/status/db.php
