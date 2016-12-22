#!/bin/bash
set -euxo pipefail

# configure nginx
# https://github.com/h5bp/server-configs-nginx
# https://support.cloudflare.com/hc/en-us/articles/200170706
# https://github.com/cloudflare/ngx_brotli_module
# https://waf.comodo.com/

mkdir -p /opt/nginx/conf/conf.d

echo '
daemon off;
worker_processes auto;
worker_rlimit_nofile 20000;
events {
	worker_connections 10000;
	multi_accept on;
	use epoll;
}
http {
	include mime.types;
	include global_params;
	vhost_traffic_status_zone;
	#server {
	#	listen 80 default_server;
	#	listen [::]:80 default_server;
	#	server_name _;
	#	if ($allowed_country = no) { return 444; }
	#	if ($http_host ~* ^www\.(.*)$ ) { return 301 $scheme://$1$request_uri; }
	#	location ^~ /.well-known/acme-challenge {
	#		alias /var/lib/letsencrypt/.well-known/acme-challenge;
	#		default_type "text/plain";
	#		try_files $uri =404;
	#	}
	#	location / { return 301 https://$host$request_uri; }
	#}
	include /opt/nginx/conf/conf.d/*.conf;
}
' > /opt/nginx/conf/nginx.conf

echo '
#aio threads;
log_format traffic "$time_iso8601,$server_name,$remote_addr,$bytes_sent,$request_length,$request_time,$status,$request_uri";
access_log /home/webuser/log/nginx/traffic.log traffic;
client_body_buffer_size 64K;
client_body_timeout 30;
client_max_body_size 1G;
default_type application/octet-stream;
gzip on;
gzip_disable "MSIE [1-6]\.(?!.*SV1)";
gzip_vary on;
gzip_http_version 1.1;
gzip_comp_level 2;
gzip_buffers 16 8k;
gzip_min_length 1k;
gzip_proxied any; #expired no-cache no-store private auth;
gzip_types text/plain application/javascript application/x-javascript text/javascript text/xml text/css application/xml;
keepalive_timeout 65;
large_client_header_buffers 4 16k;
open_file_cache          max=1000 inactive=20s;
open_file_cache_valid    60s;
open_file_cache_min_uses 5;
open_file_cache_errors   off;
rewrite_log on;
#send_timeout 10;
sendfile on;
tcp_nopush on;
tcp_nodelay on;
server_tokens off;

#limit_req zone=one burst=10;
#limit_req_zone $binary_remote_addr zone=one:10m rate=5r/s;

#server_names_hash_max_size 512;
#server_names_hash_bucket_size 64;

#geoip_country /opt/nginx/GeoIP.dat;
#map $geoip_country_code $allowed_country {
#	default yes;
#	CN no;
#	RU no;
#	VN no;
#	TW no;
#}
' > /opt/nginx/conf/global_params

# https://cipherli.st/
# https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
# https://www.ssllabs.com/ssltest/
# https://hstspreload.org/

echo '
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
ssl_dhparam /opt/nginx/conf/cert/dhparam.pem;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
#add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
#add_header X-Content-Type-Options nosniff;
#add_header X-Frame-Options DENY;
#add_header X-XSS-Protection
#add_header Public-Key-Pins
#add_header Content-Security-Policy
' > /opt/nginx/conf/ssl_params

echo '
proxy_http_version 1.1;
#proxy_set_header Connection "";
proxy_set_header Connection keep-alive;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_buffering on;
proxy_buffer_size 16k;
proxy_buffers 32 8k;
proxy_busy_buffers_size 128k;
proxy_max_temp_file_size 1024m;
proxy_temp_file_write_size 64k;
proxy_connect_timeout 10s;
proxy_read_timeout 600s;
proxy_send_timeout 30s;
#proxy_intercept_errors on;
#proxy_redirect default; #off;
#proxy_cache_bypass $http_upgrade;
' > /opt/nginx/conf/proxy_params

echo '
listen 80;
listen [::]:80;
listen 443 http2 ssl;
listen [::]:443 http2 ssl;
' > /opt/nginx/conf/listen_params

echo '
listen 80 default_server;
listen [::]:80 default_server;
listen 443 ssl http2 default_server;
listen [::]:443 ssl http2 default_server;
' > /opt/nginx/conf/listen_default_params

echo '
root /home/webuser/www;
index index.html index.default.html;
ssl_certificate         /opt/nginx/conf/cert/cert.crt;
ssl_certificate_key     /opt/nginx/conf/cert/cert.key;
ssl_trusted_certificate /opt/nginx/conf/cert/cert.crt;
include ssl_params;
location ^~ /.well-known/acme-challenge { alias /var/lib/letsencrypt/.well-known/acme-challenge; }
location /basic_status { stub_status; }
location /nginx_status { vhost_traffic_status_display; vhost_traffic_status_display_format html; }
' > /opt/nginx/conf/default_server

# clean up
rm /script_init.sh
exit 0
