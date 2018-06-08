#!/bin/bash
set -euxo pipefail

#echo "
#LOAD BALANCER SERVER
#" > /usr/share/nginx/html/index.html

/script_update.sh --no-reload
exec nginx -g "daemon off;"
