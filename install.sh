#!/bin/bash

# wget -qO - https://raw.githubusercontent.com/fffaraz/dockerweb/master/install.sh | bash

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

set -euxo pipefail

mkdir -p /opt
cd /opt
git clone https://github.com/fffaraz/dockerweb.git
export PATH=$PATH:/opt/dockerweb
echo 'PATH=$PATH:/opt/dockerweb' >> ~/.profile
