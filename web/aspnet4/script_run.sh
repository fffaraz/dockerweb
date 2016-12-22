#!/bin/bash

mkdir -p /home/webuser/www
mkdir -p /home/webuser/log
cd /home/webuser/www

[[ -f /home/webuser/project.sh ]] && source /home/webuser/project.sh
chown -R webuser:webuser /home/webuser

exec xsp4 --port=80 --logfile=/home/webuser/log/xsp4.log --verbose --printlog --loglevels=All

# mono /opt/NuGet.exe restore project.sln
# xbuild /t:Rebuild /p:WarningLevel=2 /p:Configuration=Release project.sln
# exec mono /home/webuser/project/bin/Release/project.exe
