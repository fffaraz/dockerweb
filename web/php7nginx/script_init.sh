#!/bin/bash
set -euxo pipefail

# Configure openssh

mkdir -p /etc/security
echo '
webuser hard nproc 256
' > /etc/security/limits.conf

echo '
Banner /etc/issue
LoginGraceTime 1m
PermitRootLogin no
MaxAuthTries 3
MaxSessions 1
PasswordAuthentication yes
PermitEmptyPasswords no
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
UseDNS no
MaxStartups 2:30:10
Subsystem sftp /usr/lib/ssh/sftp-server
#Subsystem sftp internal-sftp

#Match User webuser
#ForceCommand internal-sftp
#PasswordAuthentication yes
#ChrootDirectory /home/webuser
#PermitTunnel no
#AllowAgentForwarding no
#AllowTcpForwarding no
#X11Forwarding no

' > /etc/ssh/sshd_config

# Display SSH Warning Message BEFORE the Login
# https://www.cyberciti.biz/faq/howto-change-login-message/
# Ubuntu 16.04.1 LTS \n \l
echo '
WARNING : Unauthorized access to this system is forbidden and will be
prosecuted by law. By accessing this system, you agree that your actions
may be monitored if unauthorized usage is suspected.
Disconnect IMMEDIATELY if you are not an authorized user!

' > /etc/issue

# Display SSH Welcome Message AFTER the Login
# ALERT! That is a secured area. Your IP is logged. Administrator has been notified
echo '
Welcome
' > /etc/motd

# Configure nginx
# https://codex.wordpress.org/Nginx
# http://nginx.org/en/docs/http/ngx_http_log_module.html

mkdir -p /opt/nginx/conf/conf.d

echo '
daemon off;
worker_processes 1;
error_log /home/webuser/log/nginx/error.log info;
events {
	worker_connections 1024;
	multi_accept on;
	use epoll;
}
http {
	include mime.types;
	charset utf-8;
	default_type application/octet-stream;
	sendfile    on;
	tcp_nopush  on;
	tcp_nodelay on;
	keepalive_timeout 65;
	client_body_buffer_size 64K;
	client_max_body_size 1G;
	server_tokens off;
	rewrite_log on;
	open_file_cache          max=1000 inactive=20s;
	open_file_cache_valid    60s;
	open_file_cache_min_uses 5;
	open_file_cache_errors   off;
	#log_format main $http_x_forwarded_for - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent";
	access_log /home/webuser/log/nginx/access.log combined;
	index index.html index.htm index.php index.default.html;
	autoindex on;
	#set_real_ip_from 0.0.0.0/0;
	#real_ip_header X-Forwarded-For; # X-Real-IP
	map $http_x_forwarded_proto $fe_https {
		default off;
		https on;
	}
	server {
		server_name _;
		listen 80 default_server;
		listen [::]:80 default_server;
		root /home/webuser/www/public;
		include server_params;
		include /home/webuser/conf/nginx/default.conf*;
	}
	include /opt/nginx/conf/conf.d/*.conf;
	include /home/webuser/conf/nginx/conf.d/*.conf;
}
' > /opt/nginx/conf/nginx.conf

echo '
try_files $uri $uri/ /index.php$is_args$args;
location ~ [^/]\.php(/|$) {
	#try_files $uri =404;
	fastcgi_split_path_info ^(.+?\.php)(/.*)$;
	if (!-f $document_root$fastcgi_script_name) { return 404; }
	include fastcgi_params;
}
location ~ ^/(fpm_status)$ {
	#allow 1.2.3.4;
	#deny all;
	include fastcgi_params;
}
location ~* \.(?:ico|css|js|gif|jpe?g|png|JPG|svg|woff|woff2|xml)$ {
	expires max;
	access_log off;
	#log_not_found off;
	add_header Pragma public;
	add_header Cache-Control "public, must-revalidate, proxy-revalidate";
}
location ~ /\. { access_log off; log_not_found off; deny all; }
location = /favicon.ico { access_log off; log_not_found off; }
#location = /robots.txt  { access_log off; log_not_found off; }
#location ~* /(?:uploads|files)/.*\.php$ { deny all; }
' > /opt/nginx/conf/server_params

# https://www.digitalocean.com/community/tutorials/understanding-and-implementing-fastcgi-proxying-in-nginx
echo '
fastcgi_param CONTENT_LENGTH    $content_length;
fastcgi_param CONTENT_TYPE      $content_type;
fastcgi_param DOCUMENT_ROOT     $document_root;
fastcgi_param DOCUMENT_URI      $document_uri;
fastcgi_param GATEWAY_INTERFACE CGI/1.1;
fastcgi_param HTTPS             $fe_https; # $https if_not_empty;
fastcgi_param HTTP_PROXY        "";
fastcgi_param PATH_INFO         $fastcgi_path_info;
fastcgi_param PATH_TRANSLATED   $document_root$fastcgi_path_info;
fastcgi_param QUERY_STRING      $query_string;
fastcgi_param REDIRECT_STATUS   200;
fastcgi_param REMOTE_ADDR       $http_x_real_ip; # $remote_addr;
fastcgi_param REMOTE_PORT       $remote_port;
fastcgi_param REQUEST_METHOD    $request_method;
fastcgi_param REQUEST_SCHEME    $scheme;
fastcgi_param REQUEST_URI       $request_uri;
fastcgi_param SCRIPT_FILENAME   $document_root$fastcgi_script_name;
fastcgi_param SCRIPT_NAME       $fastcgi_script_name;
fastcgi_param SERVER_ADDR       $hostname; # $server_addr;
fastcgi_param SERVER_NAME       $host; # $server_name; $hostname;
fastcgi_param SERVER_PORT       $server_port;
fastcgi_param SERVER_PROTOCOL   $server_protocol;
fastcgi_param SERVER_SOFTWARE   nginx/$nginx_version;
fastcgi_buffer_size             128k;
fastcgi_buffers                 256 16k;
fastcgi_busy_buffers_size       256k;
fastcgi_index                   index.php;
fastcgi_pass                    unix:/opt/php/var/run/webuser.sock;
fastcgi_read_timeout            600;
fastcgi_temp_file_write_size    256k;
#fastcgi_ignore_client_abort    on
#fastcgi_intercept_errors       on;
' > /opt/nginx/conf/fastcgi_params

# Configure bash

cat > /etc/profile.d/aliases.sh <<'EOL'
alias ll="ls -alh"
EOL

cat > /etc/profile.d/envvars.sh <<'EOL'
export TERM=xterm
export TEMP=/home/webuser/tmp/tmp
export COMPOSER_HOME=/home/webuser/.composer
export PS1='\u@\H:\w\$ '
EOL

cat > /etc/profile.d/path.sh <<'EOL'
export PATH=$PATH:/opt/php/bin:/opt/bin:/opt/node/bin
export PATH=$PATH:/opt/.composer/vendor/bin:/home/webuser/.composer/vendor/bin
export PATH=$PATH:/home/webuser/.npm-global/bin
export PATH=$PATH:/home/webuser/spark-installer
EOL
source /etc/profile.d/path.sh

# Configure php

mkdir -p /opt/php/conf/conf.d
echo '
[PHP]
cgi.fix_pathinfo=1
#enable_dl=off
#allow_url_fopen=off
#allow_url_include=off
#disable_functions=show_source,system,shell_exec,passthru,exec,popen,proc_open,curl_exec,curl_multi_exec,parse_ini_file # ini_set
#open_basedir=/home/webuser/
display_errors=1
error_reporting=E_ALL
log_errors=1
error_log=/home/webuser/log/php/error.log
expose_php=off
max_execution_time=600
max_input_time=600
memory_limit=256M
post_max_size=1G
upload_tmp_dir=/home/webuser/tmp/php/upload
upload_max_filesize=1G
session.gc_maxlifetime=36000
session.save_path=/home/webuser/tmp/php/session
mail.add_x_header=1
mail.log=/home/webuser/log/php/mail.log
sys_temp_dir=/home/webuser/tmp/php/systemp

# realpath_cache_size=1M
# realpath_cache_ttl=120
# cgi.check_shebang_line=0

# http://php.net/manual/en/opcache.configuration.php
zend_extension=opcache.so
opcache.consistency_checks=0
opcache.enable=1
opcache.enable_cli=1
opcache.fast_shutdown=1
opcache.file_cache=/home/webuser/tmp/php/opcache
opcache.file_cache_consistency_checks=1
opcache.file_cache_only=1
opcache.interned_strings_buffer=8
opcache.load_comments=0
opcache.max_accelerated_files=4000
opcache.max_file_size=0
opcache.max_wasted_percentage=5
opcache.memory_consumption=32
opcache.revalidate_freq=60
opcache.revalidate_path=0
opcache.save_comments=0
opcache.use_cwd=1
opcache.validate_timestamps=1

[mail function]
sendmail_path=/opt/bin/phpsendmail

[Date]
date.timezone=UTC
' > /opt/php/conf/php.ini

echo '
[global]
log_level = notice
error_log = /home/webuser/log/php/php-fpm.log
emergency_restart_threshold = 10
emergency_restart_interval = 1m
process_control_timeout = 10s
events.mechanism = epoll

[webuser]
;prefix = /home/webuser
user = webuser
group = webuser
listen = /opt/php/var/run/webuser.sock
listen.owner = webuser
listen.group = webuser
listen.mode = 0660
clear_env = no
catch_workers_output = yes
request_terminate_timeout = 600s
request_slowlog_timeout = 2s
access.log = /home/webuser/log/php/access.log
access.format = "%{HTTP_X_FORWARDED_FOR}e - %R - %u %t \"%m %l %r%Q%q\" %s %f %{mili}dms %{kilo}Mkb %C%%"
;access.format = "%{HTTP_X_FORWARDED_FOR}e - [%t] \"%m %r%Q%q\" %s %l - %P %p %{seconds}d %{bytes}M %{user}C%% %{system}C%% \"%{REQUEST_URI}e\""
slowlog = /home/webuser/log/php/slow.log
security.limit_extensions = .php
php_flag[display_errors] = on
php_admin_flag[log_errors] = on
php_admin_value[memory_limit] = 256M
php_admin_value[cgi.fix_pathinfo] = 1
php_admin_value[error_log] = /home/webuser/log/php/error.log
php_value[mail.log] = /home/webuser/log/php/mail.log
;php_admin_value[sendmail_path] =

;php_value[doc_root] = /home/webuser/www/public
;php_value[upload_tmp_dir] = /home/webuser/tmp/php/upload
;php_value[session.save_path] = /home/webuser/tmp/php/session

;env[PATH] = /opt/php/bin:/sbin:/usr/sbin:/bin:/usr/bin
;env[TMPDIR] = /home/webuser/tmp/tmp
;env[TEMP] = /home/webuser/tmp/tmp
;env[TMP] = /home/webuser/tmp/tmp

pm=dynamic
pm.start_servers=1
pm.max_children=10
pm.min_spare_servers=1
pm.max_spare_servers=2
pm.max_requests=1000
;pm.process_idle_timeout=60s

pm.status_path=/fpm_status

' > /opt/php/etc/php-fpm.conf
mkdir -p /home/webuser/tmp/php/opcache
mkdir -p /home/webuser/tmp/php/systemp

# Install composer
cd /opt
mkdir -p /opt/bin
wget -qO /opt/bin/composer-setup.php https://getcomposer.org/installer
php /opt/bin/composer-setup.php --install-dir=/opt/bin --filename=composer --disable-tls
rm /opt/bin/composer-setup.php
chmod +x /opt/bin/composer
mkdir -p /opt/.composer
export COMPOSER_HOME=/opt/.composer
php /opt/bin/composer -V

# Install laravel
composer global require laravel/installer
#composer global require laravel/lumen-installer
laravel --version

# Install drush
#wget -qO /opt/bin/drush https://s3.amazonaws.com/files.drush.org/drush.phar
#chmod +x /opt/bin/drush

# Install phan 
# https://github.com/etsy/phan
#composer global require --dev etsy/phan:dev-master
#composer global install

# Install node.js & npm
NODE_VERSION=8.9.4
cd /opt
wget -q https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz
tar -xJf node-v${NODE_VERSION}-linux-x64.tar.xz
rm node-v${NODE_VERSION}-linux-x64.tar.xz
mv node-v${NODE_VERSION}-linux-x64 node

# Install gulp
npm install --global gulp-cli

# bower, yo, grunt, yarn
# sass, compass
# imagemagic, ffmpeg

# Install sendmail
cat > /opt/bin/phpsendmail <<'EOL'
#!/opt/php/bin/php
<?php

/*
https://www.howtoforge.com/how-to-log-emails-sent-with-phps-mail-function-to-detect-form-spam
This script is a sendmail wrapper for php to log calls of the php mail() function.
Author: Till Brehm, www.ispconfig.org
(Hopefully) secured by David Goodwin <david @ _palepurple_.co.uk>
*/

$sendmail_bin = '/usr/sbin/sendmail';
$logfile = '/home/webuser/log/php/phpsendmail.log';

// Get the email content
$logline = '';
$pointer = fopen('php://stdin', 'r');

$mail = '';
while ($line = fgets($pointer)) {
	if(preg_match('/^to:/i', $line) || preg_match('/^from:/i', $line)) $logline .= trim($line) . ' ';
	$mail .= $line;
}

// compose the sendmail command
$command = 'echo ' . escapeshellarg($mail) . ' | ' . $sendmail_bin . ' -t -i ';
for ($i = 1; $i < $_SERVER['argc']; $i++) $command .= escapeshellarg($_SERVER['argv'][$i]) . ' ';

// Write the log
file_put_contents($logfile, date('Y-m-d H:i:s') . ' ' . $_ENV['PWD'] . ' ' . $logline, FILE_APPEND | LOCK_EX);
// Execute the command
return shell_exec($command);

EOL
chmod +x /opt/bin/phpsendmail

# Clean up
sync
rm -rf /home/webuser
rm /script_init.sh
exit 0
