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
set -x

# Default ssl cert
mkdir -p /opt/nginx/conf/cert

if [ ! -f /opt/nginx/conf/cert/fullchain.pem ]; then
openssl req -x509 -nodes -sha256 -days 730 -newkey rsa:4096 \
-keyout /opt/nginx/conf/cert/privkey.pem -out /opt/nginx/conf/cert/fullchain.pem \
-subj "/"
cp /opt/nginx/conf/cert/fullchain.pem /opt/nginx/conf/cert/chain.pem
fi

# -subj "/subjectAltName=DNS:yoursite.com,DNS:www.yoursite.com"
# -subj "/CN=MyCertificate/subjectAltName=DNS.1=*.com,DNS.2=*.ir"
# -subj "/C=US/ST=New York/L=New York City/O=Company/OU=Department/CN=MyCertificate/emailAddress=ssl@example.com/subjectAltName=DNS.1=*"

[ ! -f /opt/nginx/conf/cert/dhparam.pem ] && openssl dhparam -out /opt/nginx/conf/cert/dhparam.pem 2048 # -5 4096

#/usr/sbin/logrotate -v

/script_update.sh --no-reload
chown -R webuser:webuser /home/webuser
exec /opt/nginx/sbin/nginx
