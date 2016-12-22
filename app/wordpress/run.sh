#!/bin/bash

if [ "$1" = "--rm" ]; then
	shift
	docker stop $1
	docker rm $1
fi

if [ $# -lt 1 ]; then
    echo "Usage: ./run.sh [--rm] NAME [SSHPORT]"
    exit 1
fi

mkdir -p /home/$1

SSHPORT=""
[ ! -z "$2" ] && SSHPORT="-p $2:22"

docker run -d --restart=always \
--name=$1 \
--net=isolated_nw \
--memory=64m \
-v /home/$1:/home/webuser \
$SSHPORT \
fffaraz/wordpress:latest
