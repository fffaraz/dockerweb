#!/bin/bash
set -euxo pipefail

groupadd webuser
useradd --no-create-home --shell /bin/bash --gid webuser webuser

apt-get update
apt-get -yq install ca-certificates nano nginx tree wget
pip install django gunicorn psycopg2 uwsgi Flask

setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/uwsgi
setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3

echo '
uwsgi_param  QUERY_STRING       $query_string;
uwsgi_param  REQUEST_METHOD     $request_method;
uwsgi_param  CONTENT_TYPE       $content_type;
uwsgi_param  CONTENT_LENGTH     $content_length;

uwsgi_param  REQUEST_URI        $request_uri;
uwsgi_param  PATH_INFO          $document_uri;
uwsgi_param  DOCUMENT_ROOT      $document_root;
uwsgi_param  SERVER_PROTOCOL    $server_protocol;
uwsgi_param  REQUEST_SCHEME     $scheme;
uwsgi_param  HTTPS              $https if_not_empty;

uwsgi_param  REMOTE_ADDR        $remote_addr;
uwsgi_param  REMOTE_PORT        $remote_port;
uwsgi_param  SERVER_PORT        $server_port;
uwsgi_param  SERVER_NAME        $server_name;
' > /etc/nginx/uwsgi_params

echo '
user webuser;
worker_processes 1;
pid /run/nginx.pid;
events {
	worker_connections 1024;
	multi_accept on;
}
http {
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	charset utf-8;
	client_max_body_size 128M;
	types_hash_max_size 2048;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	access_log /home/webuser/log/nginx/access.log;
	error_log /home/webuser/log/nginx/error.log;
	server {
		listen 80 default_server;
		location /media  {
			alias /home/webuser/www/media;
		}
		location /static {
			alias /home/webuser/www/static;
		}
		location = /favico.ico { alias /home/webuser/www/favico.ico; }
		location / {
			proxy_pass http://127.0.0.1:8000;
			proxy_set_header Host             $host;
			proxy_set_header X-Real-IP        $remote_addr;
			proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Host $server_name;

			#include uwsgi_params;
			#uwsgi_pass 127.0.0.1:8000;
			#proxy_redirect off;
		}
	}
}
' > /etc/nginx/nginx.conf

rm -rf /var/lib/apt/lists/*
rm /script_init.sh
