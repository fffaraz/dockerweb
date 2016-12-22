#!/bin/bash
set -euo pipefail

NORELOAD=0
[ $# -gt 0 ] && [ "$1" == "--no-reload" ] && NORELOAD=1
[ $# -gt 0 ] && [ "$1" == "--debug" ] && set -x

if [ ! -f /home/webuser/domains.conf ]; then
	echo "# DIRECTORY DOMAIN1 [DOMAINS...]" > /home/webuser/domains.conf
	chown webuser:webuser /home/webuser/domains.conf
fi

rm -f /opt/nginx/conf/conf.d/*.conf

sed -e '/^#/d' -e '/^$/d' /home/webuser/domains.conf | while read -r -a line; do
	DIRECTORY=${line[0]}
	SERVERNAME="server_name"
	for (( i = 1; i < ${#line[@]}; i++ )); do
		SERVERNAME=$SERVERNAME" ${line[$i]} www.${line[$i]}"
	done
	echo "
server
{
	$SERVERNAME;
	listen 80;
	root /home/webuser/$DIRECTORY/public;
	include server_params;
	include /home/webuser/conf/nginx/$DIRECTORY.conf*;
}
" > /opt/nginx/conf/conf.d/$DIRECTORY.conf
	mkdir -p /home/webuser/$DIRECTORY/public
	chown webuser:webuser /home/webuser/$DIRECTORY
	chown webuser:webuser /home/webuser/$DIRECTORY/public
done

[ $NORELOAD -eq 0 ] && /opt/nginx/sbin/nginx -s reload

exit 0
