#!/bin/bash
set -euxo pipefail

mkdir -p /home/webuser/.ssh
mkdir -p /home/webuser/log/nginx
mkdir -p /home/webuser/tmp
mkdir -p /home/webuser/www

chmod -R 700 /home/webuser/.ssh

[ ! -f /home/webuser/www/wsgi.py ] && cat > /home/webuser/www/wsgi.py <<'EOL'
def application(environ, start_response):
	start_response('200 OK', [('Content-Type', 'text/html')])
	return [b"<h1 style='color:blue'>Hello There!</h1>"]
EOL

chown -R webuser:webuser /home/webuser

[ -f /home/webuser/www/requirements.txt ] && pip install -r /home/webuser/www/requirements.txt

cd /home/webuser/www

uwsgi --uid webuser --gid webuser --socket 127.0.0.1:8000 --protocol=http --wsgi-file wsgi.py &
exec /usr/sbin/nginx

#exec uwsgi --ini myapp.ini
#exec uwsgi --json myapp.json
#exec gunicorn --bind 127.0.0.1:8000 myproject.wsgi:application
#exec python manage.py runserver 127.0.0.1:8000

#python manage.py collectstatic --noinput
#/usr/local/bin/gunicorn config.wsgi -w 4 -b 127.0.0.1:8000 --chdir=/app --log-level=DEBUG --timeout 600
