#!/bin/bash

mkdir -p /home/webuser/app
[[ -f /home/webuser/project.sh ]] && source /home/webuser/project.sh
chown -R webuser:webuser /home/webuser
cd /home/webuser/app

iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3000

npm install
exec npm start
