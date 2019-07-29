#!/bin/bash
set -euxo pipefail

#export DEBIAN_FRONTEND=noninteractive
#apt update
#apt -y upgrade
#apt -y install bash nano wget

echo "
resolver 127.0.0.11 valid=30s ipv6=off;
resolver_timeout 5s;
" > /etc/nginx/conf.d/resolver.conf

echo "
proxy_connect_timeout       600;
proxy_send_timeout          600;
proxy_read_timeout          600;
send_timeout                600;
" > /etc/nginx/conf.d/timeout.conf

# Clean up
rm -rf /var/lib/apt/lists/*
rm /script_init.sh
exit 0
