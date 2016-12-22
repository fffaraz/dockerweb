#!/bin/bash
set -euxo pipefail

apt-get -yq update
apt-get -yq install clamav

freshclam
clamscan -V
