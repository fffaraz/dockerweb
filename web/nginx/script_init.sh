#!/bin/bash
set -euxo pipefail

# configure nginx
echo '
daemon off;
worker_processes 1;
events {
	worker_connections 1024;
	use epoll;
}
http {
	include mime.types;
	default_type application/octet-stream;
	sendfile on;
	keepalive_timeout 65;
	client_max_body_size 1G;
	server_tokens off;
	rewrite_log on;
	server {
		server_name _;
		listen 80 default_server;
		root /home/webuser/www/public;
		include server_params;
	}
	include /home/webuser/conf/nginx/*.conf;
}
' > /opt/nginx/conf/nginx.conf

echo '
index index.html index.htm;
try_files $uri $uri/;
location ~* \.(?:ico|css|js|gif|jpe?g|png|JPG|svg|woff|woff2)$ {
	expires max;
	add_header Pragma public;
	add_header Cache-Control "public, must-revalidate, proxy-revalidate";
}
location / { autoindex on; }
location ~ /\. { access_log off; log_not_found off; deny all; }
location = /robots.txt  { access_log off; log_not_found off; }
location = /favicon.ico { access_log off; log_not_found off; }
' > /opt/nginx/conf/server_params

# clean up
rm /script_init.sh
