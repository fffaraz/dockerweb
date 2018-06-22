#!/bin/bash
set -euo pipefail

RELOADNGNIX=1
[ $# -gt 0 ] && [ "$1" == "--no-reload" ] && RELOADNGNIX=0
[ $# -gt 0 ] && [ "$1" == "--debug" ] && set -x

[ ! -f /home/webuser/websites.conf ] && echo "# CONTAINER CATCHALL WILDCARD SSLCERT HTTPSONLY DOMAIN1 [DOMAINS...]" > /home/webuser/websites.conf
rm -f /opt/nginx/conf/conf.d/*.conf
HASCATCHALL=0
COUNTER=0

while read -r -a line; do
	COUNTER=$((COUNTER+1))
	CONTAINER=${line[0]}
	CATCHALL=${line[1]}
	WILDCARD=${line[2]}
	SSLCERT=${line[3]}
	HTTPSONLY=${line[4]}
	DOMAIN1=${line[5]}
	# TODO: input validation

	echo -e "\nAPP: $CONTAINER\n"
	DOMAINS=""
	SERVERNAME="server_name"
	for (( i=5; i<${#line[@]}; i++ )); do
		DOMAINS=$DOMAINS"${line[$i]},www.${line[$i]},"
		if [ $WILDCARD -eq 1 ]; then
			SERVERNAME=$SERVERNAME" ${line[$i]} *.${line[$i]}"
		else
			SERVERNAME=$SERVERNAME" ${line[$i]} www.${line[$i]}"
		fi
	done
	SERVERNAME=$SERVERNAME";"

	LISTENPARAM="include listen_params;"
	HTTPREDIRECT=""
	if [ $HTTPSONLY -eq 1 ]; then
		LISTENPARAM="include listen_params_https;"
		HTTPREDIRECT="server { include listen_params_http; $SERVERNAME location / { return 301 https://\$host\$request_uri; } }"
	fi

	if [ $CATCHALL -eq 1 ]; then
		HASCATCHALL=1
		SERVERNAME="server_name _;"
		LISTENPARAM="include listen_params_default;"
	fi

	if [ $SSLCERT -eq 1 ]; then
		# TODO: dnslookup ${DOMAINS::-1} skip if failed
		CERTPLUGIN="--standalone --preferred-challenges http" # tls-sni-01
		[ $RELOADNGNIX -eq 1 ] && CERTPLUGIN="--webroot --webroot-path /var/lib/letsencrypt/"
		( set -x;
		/opt/certbot-auto certonly --non-interactive --agree-tos --no-self-upgrade --keep-until-expiring --expand \
		--email fffaraz@gmail.com \
		$CERTPLUGIN \
		--domains ${DOMAINS::-1} )
	fi

	SSLCRT="/opt/nginx/conf/cert/cert.crt"
	SSLKEY="/opt/nginx/conf/cert/cert.key"
	SSLCHAIN="/opt/nginx/conf/cert/cert.crt"
	SSLOCSP="off"
	if [ -d "/etc/letsencrypt/live/$DOMAIN1" ]; then
		SSLCRT="/etc/letsencrypt/live/$DOMAIN1/fullchain.pem"
		SSLKEY="/etc/letsencrypt/live/$DOMAIN1/privkey.pem"
		SSLCHAIN="/etc/letsencrypt/live/$DOMAIN1/chain.pem"
		SSLOCSP="on"
	fi
	if [[ $CONTAINER = *:* ]]; then
		# http://tldp.org/LDP/abs/html/string-manipulation.html
		# To replace the first match of $substring with $replacement: ${string/substring/replacement}
		# To replace all matches of $substring with $replacement: ${string//substring/replacement}
		CONTAINERARR=(${CONTAINER/:/ })
		echo "
$HTTPREDIRECT
server
{
	$LISTENPARAM
	$SERVERNAME
	location / {
		#proxy_pass http://$CONTAINER;
		set \$target_$COUNTER ${CONTAINERARR[0]};
		proxy_pass http://\$target_$COUNTER:${CONTAINERARR[1]};
		include proxy_params;
	}
	location ^~ /.well-known/acme-challenge { alias /var/lib/letsencrypt/.well-known/acme-challenge; }
	ssl_certificate         $SSLCRT;
	ssl_certificate_key     $SSLKEY;
	ssl_trusted_certificate $SSLCHAIN;
	ssl_stapling            $SSLOCSP;
	ssl_stapling_verify     $SSLOCSP;
	include ssl_params;
}
" > /opt/nginx/conf/conf.d/$COUNTER.conf
	else
		echo "
$HTTPREDIRECT
server
{
	$LISTENPARAM
	$SERVERNAME
	location / {
		#proxy_pass http://$CONTAINER.isolated_nw:80;
		set \$target_$COUNTER $CONTAINER.isolated_nw;
		proxy_pass http://\$target_$COUNTER:80;
		include proxy_params;
	}
	location ^~ /.well-known/acme-challenge { alias /var/lib/letsencrypt/.well-known/acme-challenge; }
	ssl_certificate         $SSLCRT;
	ssl_certificate_key     $SSLKEY;
	ssl_trusted_certificate $SSLCHAIN;
	ssl_stapling            $SSLOCSP;
	ssl_stapling_verify     $SSLOCSP;
	include ssl_params;
}
" > /opt/nginx/conf/conf.d/$COUNTER.conf
	fi

done < <(sed -e '/^#/d' -e '/^$/d' /home/webuser/websites.conf)

if [ $HASCATCHALL -eq 0 ]; then
	echo '
server
{
	server_name _ "";
	include listen_params_default;
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

[ $RELOADNGNIX -eq 1 ] && /opt/nginx/sbin/nginx -s reload

#mv access.log access.log.0
#kill -USR1 `cat master.nginx.pid`
#sleep 1
#gzip access.log.0

exit 0
