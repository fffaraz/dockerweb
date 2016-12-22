#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/.ssh
mkdir -p /home/webuser/log/nginx
mkdir -p /home/webuser/conf/nginx
mkdir -p /home/webuser/cache/nginx/tmp_client
mkdir -p /home/webuser/cache/nginx/tmp_proxy
mkdir -p /home/webuser/cache/nginx/tmp_fastcgi
mkdir -p /home/webuser/cache/nginx/tmp_uwsgi
mkdir -p /home/webuser/cache/nginx/tmp_scgi
mkdir -p /home/webuser/www/public

env > /home/webuser/.env
echo 'It works!' > /home/webuser/www/public/index.htm

chown -R webuser:webuser /home/webuser
chmod -R 700 /home/webuser/.ssh

[[ -f /script_run_aux.sh ]] && source /script_run_aux.sh

if [ ! -z ${WEBUSER_PASSWORD:+x} ]; then
	echo "webuser:$WEBUSER_PASSWORD" | chpasswd
	/usr/sbin/sshd
fi

/script_update.sh --no-reload

# tail -f /var/www/logs/*.log &

exec /opt/nginx/sbin/nginx
