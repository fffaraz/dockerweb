#!/bin/bash

echo "<html><body><h1>It works!</h1></body></html>" > /home/webuser/www/public/index.html

if [ -z "${PHPMYADMIN:+x}" ]; then
	if [ ! -L /home/webuser/www/public/pma ]; then
		ln -s /opt/phpMyAdmin /home/webuser/www/public/pma
	fi
else
	if [ ! -L /home/webuser/www/public/$PHPMYADMIN ]; then
		ln -s /opt/phpMyAdmin /home/webuser/www/public/$PHPMYADMIN
	fi
fi

if [ -z "${PHPSTATUS:+x}" ]; then
	if [ ! -L /home/webuser/www/public/status ]; then
		ln -s /opt/status /home/webuser/www/public/status
	fi
else
	if [ ! -L /home/webuser/www/public/$PHPSTATUS ]; then
		ln -s /opt/status /home/webuser/www/public/$PHPSTATUS
	fi
fi

echo $MYSQL_ROOT_PASSWORD > /opt/mysql_root_password.txt

sed -i -e "s/__CaptchaPublic__/${CaptchaPublic}/" /opt/phpMyAdmin/config.inc.php
sed -i -e "s/__CaptchaPrivate__/${CaptchaPrivate}/" /opt/phpMyAdmin/config.inc.php
sed -i -e "s/__MYSQLSERVER__/${MYSQL_SERVER}/" /opt/phpMyAdmin/config.inc.php
sed -i -e "s/__MYSQLSERVER__/${MYSQL_SERVER}/" /opt/status/db.php
