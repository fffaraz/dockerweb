#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt update
apt -y upgrade
apt -y install bash nano wget

echo "
resolver 127.0.0.11 valid=30s ipv6=off;
resolver_timeout 5s;
" >> /etc/nginx/conf.d/default.conf

# Clean up
rm -rf /var/lib/apt/lists/*
rm /script_init.sh
exit 0
