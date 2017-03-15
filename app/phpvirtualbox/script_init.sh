#!/bin/bash
set -euxo pipefail

# https://github.com/imoore76/phpvirtualbox
# vboxwebsrv --host 172.17.0.1 --authentication null

PVB_VERSION=5.0-5
cd /opt
wget --no-verbose -O phpvirtualbox.zip https://sourceforge.net/projects/phpvirtualbox/files/phpvirtualbox-$PVB_VERSION.zip/download
unzip -q phpvirtualbox.zip
rm phpvirtualbox.zip
mv phpvirtualbox-$PVB_VERSION phpvirtualbox

wget --no-verbose -O /opt/phpvirtualbox/endpoints/lib/vboxconnector.php https://raw.githubusercontent.com/mikedld/phpvirtualbox/10b6a7383c810dfa6261869cb1f9cc8bca2ad814/endpoints/lib/vboxconnector.php

cat > /opt/phpvirtualbox/config.php <<'EOL'
<?php
class phpVBoxConfig {
var $username = '';
var $password = '';
var $location = 'http://172.17.0.1:18083/';
var $language = 'en';
var $vrdeports = '9000-9100';
var $maxProgressList = 5;
var $deleteOnRemove = true;
var $browserRestrictFiles = array('.iso','.vdi','.vmdk','.img','.bin','.vhd','.hdd','.ovf','.ova','.xml','.vbox','.cdr','.dmg','.ima','.dsk','.vfd');
var $hostMemInfoRefreshInterval = 5;
var $consoleResolutions = array('640x480','800x600','1024x768','1280x720','1440x900');
var $consoleKeyboardLayout = 'EN';
var $nicMax = 4;
var $noAuth = true;
}
EOL

rm /script_init.sh
exit 0
