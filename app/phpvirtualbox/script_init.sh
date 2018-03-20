#!/bin/bash
set -euxo pipefail

# https://github.com/phpvirtualbox/phpvirtualbox
# https://github.com/clue/docker-phpvirtualbox

# killall vboxwebsrv
# vboxwebsrv --host 172.17.0.1 --authentication null --background
# --port 18083
# --pidfile
# --logfile

cd /opt
wget -q -O phpvirtualbox.zip https://github.com/phpvirtualbox/phpvirtualbox/archive/develop.zip
unzip -q phpvirtualbox.zip
rm phpvirtualbox.zip
mv phpvirtualbox-develop phpvirtualbox

cat > /opt/phpvirtualbox/config.php <<'EOL'
<?php
class phpVBoxConfig {
var $username = 'vbox';
var $password = 'pass';
var $location = 'http://172.17.0.1:18083/';
var $language = 'en';
var $vrdeports = '9000-9100';
var $maxProgressList = 5;
var $deleteOnRemove = true;
var $browserRestrictFiles = ['.iso','.vdi','.vmdk','.img','.bin','.vhd','.hdd','.ovf','.ova','.xml','.vbox','.cdr','.dmg','.ima','.dsk','.vfd'];
var $hostMemInfoRefreshInterval = 5;
var $consoleResolutions = ['640x480','800x600','1024x768','1280x720','1440x900'];
var $consoleKeyboardLayout = 'EN';
var $nicMax = 4;
var $noAuth = true;
}
EOL

rm /script_init.sh
exit 0
