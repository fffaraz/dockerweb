#!/bin/bash

# wget -qO - https://raw.githubusercontent.com/fffaraz/dockerweb/master/install.sh | bash

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

set -euxo pipefail

sed -i "s/Port 22/Port 7071/" /etc/ssh/sshd_config
service ssh restart

export DEBIAN_FRONTEND=noninteractive
apt-get -yq update < /dev/null
apt-get -yq upgrade < /dev/null
apt-get -yq dist-upgrade < /dev/null
apt-get -yq --fix-broken install < /dev/null
apt-get -yq install apt-transport-https ca-certificates git wget < /dev/null

mkdir -p /opt
git clone https://github.com/fffaraz/dockerweb.git /opt/dockerweb

echo 'export PATH=$PATH:/opt/dockerweb' >> ~/.profile

#echo 'alias docweb="/opt/dockerweb/docweb"' >> ~/.bash_aliases
#alias docweb="/opt/dockerweb/docweb"

#cat /proc/meminfo | grep SwapTotal:
#cat /proc/meminfo | grep MemTotal:
#docweb install:swapfile 1024

#docweb bootstrap

# bash completion for the `docweb` command

# _docweb_complete() {
# 	local OLD_IFS="$IFS"
# 	local cur=${COMP_WORDS[COMP_CWORD]}

# 	IFS=$'\n';  # want to preserve spaces at the end
# 	local opts="$(docweb cli completions --line="$COMP_LINE" --point="$COMP_POINT")"

# 	if [[ "$opts" =~ \<file\>\s* ]]
# 	then
# 		COMPREPLY=( $(compgen -f -- $cur) )
# 	elif [[ $opts = "" ]]
# 	then
# 		COMPREPLY=( $(compgen -f -- $cur) )
# 	else
# 		COMPREPLY=( ${opts[*]} )
# 	fi

# 	IFS="$OLD_IFS"
# 	return 0
# }
# complete -o nospace -F _docweb_complete docweb
