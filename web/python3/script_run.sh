#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/.ssh
mkdir -p /home/webuser/log
mkdir -p /home/webuser/tmp
mkdir -p /home/webuser/www

chmod -R 700 /home/webuser/.ssh

[[ ! -f /script_run_aux.sh ]] && cat > /home/webuser/www/wsgi.py <<'EOL'
def application(environ, start_response):
	start_response('200 OK', [('Content-Type', 'text/html')])
	return [b"<h1 style='color:blue'>Hello There!</h1>"]
EOL

chown -R webuser:webuser /home/webuser

cd /home/webuser/www

# --uid webuser --gid webuser
# --workers 1 --threads 10
exec uwsgi --socket 0.0.0.0:80 --protocol=http -w wsgi

#exec uwsgi --ini myapp.ini
#exec gunicorn --bind 0.0.0.0:80 myproject.wsgi:application
#exec ./manage.py runserver 0.0.0.0:80

#python /app/manage.py collectstatic --noinput
#/usr/local/bin/gunicorn config.wsgi -w 4 -b 0.0.0.0:5000 --chdir=/app --log-level=DEBUG --timeout 600
