#!/bin/bash
set -euxo pipefail

wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1
rm latest.tar.gz

mv wp-config-sample.php wp-config.php
sed -i s/database_name_here/$WP_DB_NAME/ wp-config.php
sed -i s/username_here/$WP_DB_USERNAME/ wp-config.php
sed -i s/password_here/$WP_DB_PASSWORD/ wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php

curl "http://$WP_DOMAIN/wp-admin/install.php?step=2" \
--data-urlencode "weblog_title=$WP_DOMAIN"\
--data-urlencode "user_name=$WP_ADMIN_USERNAME" \
--data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
--data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
--data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
--data-urlencode "pw_weak=1"

echo "add_filter( 'allow_dev_auto_core_updates', '__return_false' );" >> wp-config.php
echo "add_filter( 'allow_minor_auto_core_updates', '__return_true' );" >> wp-config.php
echo "add_filter( 'allow_major_auto_core_updates', '__return_true' );" >> wp-config.php
echo "add_filter( 'auto_update_plugin', '__return_true' );" >> wp-config.php
echo "add_filter( 'auto_update_theme', '__return_true' );" >> wp-config.php

echo "define('DISALLOW_FILE_EDIT', true);" >> wp-config.php

sed -i "s/define('AUTH_KEY',\s*'put your unique phrase here');/define('AUTH_KEY', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('SECURE_AUTH_KEY',\s*'put your unique phrase here');/define('SECURE_AUTH_KEY', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('LOGGED_IN_KEY',\s*'put your unique phrase here');/define('LOGGED_IN_KEY', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('NONCE_KEY',\s*'put your unique phrase here');/define('NONCE_KEY', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('AUTH_SALT',\s*'put your unique phrase here');/define('AUTH_SALT', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('SECURE_AUTH_SALT',\s*'put your unique phrase here');/define('SECURE_AUTH_SALT', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('LOGGED_IN_SALT',\s*'put your unique phrase here');/define('LOGGED_IN_SALT', '`pwgen -1 -s 64`');/" wp-config.php
sed -i "s/define('NONCE_SALT',\s*'put your unique phrase here');/define('NONCE_SALT', '`pwgen -1 -s 64`');/" wp-config.php

rm $WP_PATH/public/readme*

# https://github.com/wp-cli/wp-cli

# Clean up
rm /script_init.sh
