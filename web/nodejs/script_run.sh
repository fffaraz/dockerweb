#!/bin/bash

mkdir -p /home/webuser/app
[[ -f /home/webuser/project.sh ]] && source /home/webuser/project.sh
chown -R webuser:webuser /home/webuser
cd /home/webuser/app

npm install

exec npm start
#exec yarn start
