#!/bin/bash

# wget -qO - https://raw.githubusercontent.com/fffaraz/dockerweb/master/install.sh | bash

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

set -euxo pipefail

apt-get -yq update
apt-get -yq install git

mkdir -p /opt
git clone https://github.com/fffaraz/dockerweb.git /opt/dockerweb

export PATH=$PATH:/opt/dockerweb
echo 'export PATH=$PATH:/opt/dockerweb' >> ~/.profile

#alias docweb="/opt/dockerweb/docweb"
#echo 'alias docweb="/opt/dockerweb/docweb"' >> ~/.bash_aliases

#docweb install:swapfile 1024
docweb bootstrap
