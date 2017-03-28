#!/bin/bash
set -euxo pipefail

rm -rf /home/webuser/tmp
mkdir -p /home/webuser/.ssh
mkdir -p /home/webuser/backup
mkdir -p /home/webuser/log/php
mkdir -p /home/webuser/log/nginx
mkdir -p /home/webuser/conf/nginx
mkdir -p /home/webuser/conf/nginx/conf.d
mkdir -p /home/webuser/tmp/tmp
mkdir -p /home/webuser/tmp/php/opcache
mkdir -p /home/webuser/tmp/php/upload
mkdir -p /home/webuser/tmp/php/session
mkdir -p /home/webuser/tmp/php/systemp
mkdir -p /home/webuser/tmp/nginx/client
mkdir -p /home/webuser/tmp/nginx/proxy
mkdir -p /home/webuser/tmp/nginx/fastcgi
mkdir -p /home/webuser/tmp/nginx/uwsgi
mkdir -p /home/webuser/tmp/nginx/scgi
mkdir -p /home/webuser/www/public

rm -rf /tmp
ln -s /home/webuser/tmp/tmp /tmp
chmod 1777 /tmp
chmod -R 700 /home/webuser/.ssh

find /home/webuser/www -type d -exec chmod 0755 {} \;
find /home/webuser/www -type f -exec chmod 0644 {} \;

NEWUSER=$(hostname | tr -d "_.-")
useradd --no-create-home --home-dir /home/$NEWUSER --shell /bin/bash --gid webuser --non-unique --uid $(id -u webuser) $NEWUSER
ln -s /home/webuser /home/$NEWUSER

# /var/tmp
# /etc/shells

PS1='$ '
source /etc/profile
env > /home/webuser/tmp/envvars
set +x
echo '<?php phpinfo();' > /home/webuser/www/public/_info_.php
echo "
<!DOCTYPE html>
<html>
<head>
<meta charset=\"utf-8\">
<title>$(hostname)</title>
<style>
	body {
		width: 35em;
		margin: 0 auto;
		font-family: Tahoma, Verdana, Arial, sans-serif;
	}
	h1 {
		text-transform: uppercase;
	}
</style>
</head>
<body>
<h1>$(hostname)</h1>
<p>If you see this page, the web server is successfully installed and working.
Further configuration is required.</p>
</body>
</html>
" > /home/webuser/www/public/index.default.html
set -x

[[ -f /script_run_aux.sh ]] && source /script_run_aux.sh
chown -R webuser:webuser /home/webuser
[[ -f /home/webuser/project.sh ]] && su webuser -c '/bin/bash /home/webuser/project.sh'
/script_update.sh --no-reload

if [ -f /home/webuser/www/composer.json ]; then
	echo "Found 'composer.json', installing dependencies ..."
	#composer install --no-interaction --no-ansi --optimize-autoloader
fi

if [ ! -z "${WEBUSER_PASSWORD:+x}" ]; then
	echo "webuser:${WEBUSER_PASSWORD}" | chpasswd
	echo "${NEWUSER}:${WEBUSER_PASSWORD}" | chpasswd
	#/usr/sbin/sshd
	dropbear -Ewgjk -b /etc/issue -p 22 -K 120 -I 1200
	#		svr-runopts.c
	# -b	bannerfile
	# -d	dsskey
	# -r	rsakey
	# -R	Create hostkeys as required
	# -F	Don't fork into background
	# -E	Log to stderr rather than syslog
	# -m	Don't display the motd on login
	# -w	Disallow root logins
	# -s	Disable password logins
	# -g	Disable password logins for root
	# -j	Disable local port forwarding
	# -k	Disable remote port forwarding
	# -p	[address:]port
	# -i	Service program mode
	# -P	pidfile
	# -a	Allow remote hosts to connect to forwarded ports
	# -W	windowsize
	# -K	timeout_seconds
	# -I	idle_timeout
	# no-port-forwarding
	# no-agent-forwarding
	# no-X11-forwarding
	# no-pty
	# command="forced_command"
fi

/opt/php/sbin/php-fpm
chmod 644 /home/webuser/log/php/*.log
exec /opt/nginx/sbin/nginx
