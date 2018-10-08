#!/bin/bash
set -euo pipefail

RELOADNGNIX=1
[ $# -gt 0 ] && [ "$1" == "--no-reload" ] && RELOADNGNIX=0
[ $# -gt 0 ] && [ "$1" == "--debug" ] && set -x

[ ! -f /home/webuser/upstreams.conf ] && echo "# DOMAIN UPSTREAM1 [UPSTREAMS...]" > /home/webuser/upstreams.conf

find /etc/nginx/conf.d -type f ! -name 'default.conf' -delete
#rm -f /etc/nginx/conf.d/*.conf

# https://stackoverflow.com/questions/34741571/nginx-tcp-forwarding-based-on-hostname

COUNTER=0

while read -r -a line; do
	COUNTER=$((COUNTER+1))
	DOMAIN=${line[0]}
	SERVERNAME=""
	#TODO: SERVERNAME="server_name $DOMAIN;"
	UPSTREAMS=""
	for (( i=1; i<${#line[@]}; i++ )); do
		UPSTREAMS=$UPSTREAMS"server ${line[$i]};\n\t"
	done
	echo -e "
upstream upstream_$COUNTER {
	least_conn;
	$UPSTREAMS
}

server {
	listen 80;
	$SERVERNAME
	location / {
		proxy_pass http://upstream_$COUNTER;
		proxy_redirect off;
		proxy_http_version 1.1;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Host \$server_name;
		proxy_set_header X-Forwarded-Proto \$scheme;
	}
}
" > /etc/nginx/conf.d/line_$COUNTER.conf

done < <(sed -e '/^#/d' -e '/^$/d' /home/webuser/upstreams.conf)

nginx -t
[ $RELOADNGNIX -eq 1 ] && nginx -s reload

exit 0
