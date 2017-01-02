#!/bin/bash
set -euxo pipefail

# Configure nginx
# https://github.com/h5bp/server-configs-nginx
# https://support.cloudflare.com/hc/en-us/articles/200170706
# https://github.com/cloudflare/ngx_brotli_module
# https://waf.comodo.com/

mkdir -p /opt/nginx/conf/conf.d

echo '
daemon off;
worker_processes auto;
worker_rlimit_nofile 20000;
#include /home/webuser/conf/nginx/core.d/*.conf;
events {
	worker_connections 10000;
	multi_accept on;
	use epoll;
	#include /home/webuser/conf/nginx/events.d/*.conf;
}
http {
	include mime.types;
	include global_params;
	vhost_traffic_status_zone;
	#include /home/webuser/conf/nginx/http.d/*.conf;
	#server {
	#	listen 80 default_server;
	#	listen [::]:80 default_server;
	#	server_name _;
	#	if ($allowed_country = no) { return 444; }
	#	if ($http_host ~* ^www\.(.*)$ ) { return 301 $scheme://$1$request_uri; }
	#	location ^~ /.well-known/acme-challenge {
	#		alias /var/lib/letsencrypt/.well-known/acme-challenge;
	#		try_files $uri =404;
	#		default_type "text/plain";
	#	}
	#	location / { return 301 https://$host$request_uri; }
	#}
	include /opt/nginx/conf/conf.d/*.conf;
}
' > /opt/nginx/conf/nginx.conf

echo '
#aio threads;
default_type application/octet-stream;

log_format traffic "$time_iso8601,$server_name,$remote_addr,$bytes_sent,$request_length,$request_time,$status,$request_uri";
access_log /home/webuser/log/nginx/traffic.log traffic;

#log_format main $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for" $request_length $request_time "$upstream_response_length" "$upstream_response_time" "$host";
#access_log /home/webuser/log/nginx/access.log  main;

client_body_buffer_size 64K;
client_body_timeout 30;
client_max_body_size 1G;

gzip on;
gzip_disable "msie6";
#gzip_disable "MSIE [1-6]\.(?!.*SV1)";
gzip_vary on;
gzip_http_version 1.1;
gzip_comp_level 2; #6
gzip_buffers 16 8k;
gzip_min_length 512;
gzip_proxied any; #expired no-cache no-store private auth;
gzip_types text/plain text/xml text/css text/javascript application/javascript application/x-javascript application/json application/xml application/xml+rss application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;
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

# CloudFlare proxy addresses
set_real_ip_from    103.21.244.0/22;
set_real_ip_from    103.22.200.0/22;
set_real_ip_from    103.31.4.0/22;
set_real_ip_from    104.16.0.0/12;
set_real_ip_from    108.162.192.0/18;
set_real_ip_from    131.0.72.0/22;
set_real_ip_from    141.101.64.0/18;
set_real_ip_from    162.158.0.0/15;
set_real_ip_from    172.64.0.0/13;
set_real_ip_from    173.245.48.0/20;
set_real_ip_from    188.114.96.0/20;
set_real_ip_from    190.93.240.0/20;
set_real_ip_from    197.234.240.0/22;
set_real_ip_from    198.41.128.0/17;
set_real_ip_from    199.27.128.0/21;
set_real_ip_from    2400:cb00::/32;
set_real_ip_from    2405:8100::/32;
set_real_ip_from    2405:b500::/32;
set_real_ip_from    2606:4700::/32;
set_real_ip_from    2803:f800::/32;
set_real_ip_from    2c0f:f248::/32;
set_real_ip_from    2a06:98c0::/29;
real_ip_header      X-Forwarded-For;

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
location /basic_status { stub_status; }
location /nginx_status { vhost_traffic_status_display; vhost_traffic_status_display_format html; }
location ^~ /.well-known/acme-challenge { alias /var/lib/letsencrypt/.well-known/acme-challenge; }
ssl_certificate         /opt/nginx/conf/cert/cert.crt;
ssl_certificate_key     /opt/nginx/conf/cert/cert.key;
ssl_trusted_certificate /opt/nginx/conf/cert/cert.crt;
include ssl_params;
' > /opt/nginx/conf/default_server

# Clean up
rm /script_init.sh
exit 0
