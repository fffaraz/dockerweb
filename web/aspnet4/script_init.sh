#!/bin/sh
set -euxo pipefail

# requirements
addgroup webuser
adduser --disabled-password --no-create-home --shell /bin/bash --gecos "" --home /home/webuser --ingroup webuser webuser

# install mono

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/debian wheezy main" | tee /etc/apt/sources.list.d/mono-xamarin.list
#echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list
#echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list

export DEBIAN_FRONTEND=noninteractive
apt-get -yq update < /dev/null
apt-get -yq upgrade < /dev/null

apt-get install -yq wget
apt-get install -yq mono-complete
apt-get install -yq mono-xsp4
#apt-get install -yq mono-devel
#apt-get install -yq referenceassemblies-pcl
#mozroots --import --sync

mkdir -p /opt
cd /opt
wget https://github.com/NuGet/Home/releases/download/3.3/NuGet.exe

# clean up
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm /script_init.sh
