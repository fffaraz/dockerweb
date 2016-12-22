#!/bin/bash
set -euxo pipefail

groupadd -o -g 33 webuser
useradd -o -u 33 -g webuser webuser

apt-get update
apt-get -yq install nano wget

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm /script_init.sh
