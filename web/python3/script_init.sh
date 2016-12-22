#!/bin/bash
set -euxo pipefail

groupadd webuser
useradd --no-create-home --shell /bin/bash --gid webuser webuser

apt-get update
apt-get -yq install nano wget
pip install uwsgi django gunicorn psycopg2 Flask

setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/uwsgi

rm /script_init.sh
