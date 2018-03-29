#!/bin/bash
set -euxo pipefail
export TERM=xterm

rm -rf /home/webuser/tmp
mkdir -p /home/webuser/tmp/nginx/client
mkdir -p /home/webuser/tmp/nginx/proxy
mkdir -p /home/webuser/tmp/nginx/fastcgi
mkdir -p /home/webuser/tmp/nginx/uwsgi
mkdir -p /home/webuser/tmp/nginx/scgi
mkdir -p /home/webuser/log/nginx
mkdir -p /home/webuser/www

SERVER_NAME=$(hostname)
[ $# -gt 0 ] && SERVER_NAME=$1

set +x
echo "
<!DOCTYPE html>
<html>
<head>
<meta charset=\"utf-8\">
<title>$SERVER_NAME</title>
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
<h1>$SERVER_NAME</h1>
<p>If you see this page, the web server is successfully installed and working.
Further configuration is required.</p>
</body>
</html>
" > /home/webuser/www/index.default.html

#/usr/sbin/logrotate -v

set -x
/script_update.sh --no-reload
chown -R webuser:webuser /home/webuser
exec /opt/nginx/sbin/nginx
