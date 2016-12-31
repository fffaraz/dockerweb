#!/bin/bash
set -euo pipefail

NORELOAD=0
[ $# -gt 0 ] && [ "$1" == "--no-reload" ] && NORELOAD=1
[ $# -gt 0 ] && [ "$1" == "--debug" ] && set -x

[ ! -f /home/webuser/websites.conf ] && echo "# CONTAINER CATCHALL WILDCARD SSLCERT DOMAIN1 [DOMAINS...]" > /home/webuser/websites.conf
rm -f /opt/nginx/conf/conf.d/*.conf
HASCATCHALL=0

while read -r -a line; do
	CONTAINER=${line[0]}
	CATCHALL=${line[1]}
	WILDCARD=${line[2]}
	SSLCERT=${line[3]}
	DOMAIN1=${line[4]}
	# TODO: input validation

	echo -e "\nAPP: $CONTAINER\n"
	DOMAINS=""
	SERVERNAME="include listen_params; server_name"
	for (( i=4; i<${#line[@]}; i++ )); do
		DOMAINS=$DOMAINS"${line[$i]},www.${line[$i]},"
		if [ $WILDCARD -eq 1 ]; then
			SERVERNAME=$SERVERNAME" ${line[$i]} *.${line[$i]}"
		else
			SERVERNAME=$SERVERNAME" ${line[$i]} www.${line[$i]}"
		fi
	done
	SERVERNAME=$SERVERNAME";"

	if [ $CATCHALL -eq 1 ]; then
		HASCATCHALL=1
		SERVERNAME="include listen_default_params; server_name _;"
	fi

	[ $NORELOAD -eq 1 ] && [ $SSLCERT -eq 1 ] && \
	( set -x; /opt/certbot-auto certonly -n --agree-tos --email fffaraz@gmail.com \
	--keep-until-expiring \
	--standalone --preferred-challenges tls-sni-01 \
	--domains ${DOMAINS::-1} )
	# --webroot --webroot-path /var/lib/letsencrypt/
	# --renew-by-default

	SSLCRT="/opt/nginx/conf/cert/cert.crt"
	SSLKEY="/opt/nginx/conf/cert/cert.key"
	if [ -d "/etc/letsencrypt/live/$DOMAIN1" ]; then
		SSLCRT="/etc/letsencrypt/live/$DOMAIN1/fullchain.pem"
		SSLKEY="/etc/letsencrypt/live/$DOMAIN1/privkey.pem"
	fi
	echo "
server
{
	$SERVERNAME
	location / {
		#set $target http://$CONTAINER.isolated_nw:80;
		#proxy_pass http://$target;
		proxy_pass http://$CONTAINER.isolated_nw:80;
		include proxy_params;
	}
	location ^~ /.well-known/acme-challenge { alias /var/lib/letsencrypt/.well-known/acme-challenge; }
	ssl_certificate         $SSLCRT;
	ssl_certificate_key     $SSLKEY;
	ssl_trusted_certificate $SSLCRT;
	include ssl_params;
}
" > /opt/nginx/conf/conf.d/$CONTAINER.conf

done < <(sed -e '/^#/d' -e '/^$/d' /home/webuser/websites.conf)

if [ $HASCATCHALL -eq 0 ]; then
	echo '
server
{
	server_name _ "";
	include listen_default_params;
	include default_server;
}
' > /opt/nginx/conf/conf.d/default_server.conf
else
	echo '
server
{
	server_name "";
	include listen_params;
	include default_server;
}
' > /opt/nginx/conf/conf.d/default_server.conf
fi

/opt/nginx/sbin/nginx -t

[ $NORELOAD -eq 0 ] && /opt/nginx/sbin/nginx -s reload

#mv access.log access.log.0
#kill -USR1 `cat master.nginx.pid`
#sleep 1
#gzip access.log.0

exit 0
