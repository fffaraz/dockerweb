#!/bin/bash

if [ ! -f /home/webuser/www/public/pvb ]; then
	echo "<html><body><h1>It works!</h1></body></html>" > /home/webuser/www/public/index.html
	ln -s /opt/phpvirtualbox /home/webuser/www/public/pvb
fi
