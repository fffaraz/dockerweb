#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND='noninteractive'
apt-get -yq update
apt-get -yq install samba
