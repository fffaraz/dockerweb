#!/bin/bash
set -euxo pipefail

# Install phpMyAdmin
# https://www.phpmyadmin.net/downloads/
# https://github.com/phpmyadmin/phpmyadmin/releases
# https://github.com/phpmyadmin/phpmyadmin/archive/RELEASE_4_6_5_2.zip

PMA_VERSION=4.6.5.2
cd /opt
wget --no-verbose https://files.phpmyadmin.net/phpMyAdmin/$PMA_VERSION/phpMyAdmin-$PMA_VERSION-english.zip
unzip -q phpMyAdmin-$PMA_VERSION-english.zip
rm phpMyAdmin-$PMA_VERSION-english.zip
mv phpMyAdmin-$PMA_VERSION-english phpMyAdmin

# http://docs.phpmyadmin.net/en/latest/config.html
# https://www.google.com/recaptcha/

# https://github.com/nazar-pc/docker-phpmyadmin/blob/master/config.inc.php

cat > /opt/phpMyAdmin/config.inc.php <<'EOL'
<?php
$cfg['blowfish_secret'] = '__SECRET__';
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['ShowAll'] = true;
$cfg['LoginCookieValidity'] = 36000;
$cfg['MaxRows'] = 100;
$cfg['SendErrorReports'] = 'never';
$cfg['VersionCheck'] = false;
$cfg['ExecTimeLimit'] = 600;
$cfg['CaptchaLoginPublicKey'] = '__CaptchaPublic__';
$cfg['CaptchaLoginPrivateKey'] = '__CaptchaPrivate__';

$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['Servers'][1]['connect_type'] = 'tcp';
$cfg['Servers'][1]['compress'] = false;
$cfg['Servers'][1]['AllowRoot'] = true;
$cfg['Servers'][1]['AllowNoPassword'] = false;
$cfg['Servers'][1]['host'] = '__MYSQLSERVER__.isolated_nw';
$cfg['Servers'][1]['verbose'] = '__MYSQLSERVER__';
$cfg['Servers'][1]['hide_db'] = '^(information_schema|performance_schema|mysql|sys)$';

$cfg['Servers'][2]['auth_type'] = 'cookie';
$cfg['Servers'][2]['connect_type'] = 'tcp';
$cfg['Servers'][2]['compress'] = false;
$cfg['Servers'][2]['AllowRoot'] = true;
$cfg['Servers'][2]['AllowNoPassword'] = false;
$cfg['Servers'][2]['host'] = 'db2.isolated_nw';
$cfg['Servers'][2]['verbose'] = 'db2';
$cfg['Servers'][2]['hide_db'] = '^(information_schema|performance_schema|mysql|sys)$';

$cfg['Servers'][3]['auth_type'] = 'cookie';
$cfg['Servers'][3]['connect_type'] = 'tcp';
$cfg['Servers'][3]['compress'] = false;
$cfg['Servers'][3]['AllowRoot'] = true;
$cfg['Servers'][3]['AllowNoPassword'] = false;
$cfg['Servers'][3]['host'] = 'db3.isolated_nw';
$cfg['Servers'][3]['verbose'] = 'db3';
$cfg['Servers'][3]['hide_db'] = '^(information_schema|performance_schema|mysql|sys)$';

EOL

# http://www.howtogeek.com/howto/30184/10-ways-to-generate-a-random-password-from-the-command-line/
# date | sha256sum | base64 | head -c 32
sed -i -e "s/__SECRET__/$(date | md5sum | base64)/" /opt/phpMyAdmin/config.inc.php

# Install php database status
mkdir /opt/status

cat > /opt/status/db.php <<'EOL'
<?php

$mysql_server='__MYSQLSERVER__';

$link = mysqli_connect($mysql_server, 'root', trim(file_get_contents('/opt/mysql_root_password.txt')));
if (!$link) die("\n<br />\nError connecting to MySQL server.\n");

EOL

cat > /opt/status/index.php <<'EOL'
<?php

require 'db.php';

$result = mysqli_query($link, 'SHOW DATABASES');
if (!$result) die("Error: " . mysqli_error($link));

echo '<center><br><br>';
while ($row = mysqli_fetch_row($result))
{
	if ($row[0] != 'information_schema' && $row[0] != 'performance_schema' && $row[0] != 'mysql' && $row[0] != 'sys')
	{
		echo '<table border="1">';
		echo "<tr><th colspan=\"4\"><a href=\"table.php?db=$row[0]\">$row[0]</a></th></tr>";
		echo "<tr><th>TABLE NAME</th><th>TABLE ROWS</th><th>DATA LENGTH</th><th>INDEX LENGTH</th></tr>";
		$tables = mysqli_query($link, "SELECT TABLE_NAME,TABLE_ROWS,DATA_LENGTH,INDEX_LENGTH FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA LIKE '$row[0]'");
		if (!$tables) die("Error: " . mysqli_error($link));
		$total_rows = 0;
		$total_data = 0;
		$total_index = 0;			
		while ($table = mysqli_fetch_row($tables))
		{
			$table_mb = array();
			$table_mb[2] = round($table[2] / (1024*1024), 2);
			$table_mb[3] = round($table[3] / (1024*1024), 2);
			echo "<tr><td>$table[0]</td><td>$table[1]</td><td>$table_mb[2]</td><td>$table_mb[3]</td></tr>";
			$total_rows += $table[1];
			$total_data += $table[2];
			$total_index += $table[3];
		}
		$total_data_mb = round($total_data / (1024*1024), 2);
		$total_index_mb = round($total_index / (1024*1024), 2);
		echo "<tr><th>TOTAL</th><th>$total_rows</th><th>$total_data_mb</th><th>$total_index_mb</th></tr>";
		echo '</table><br><hr><br>';
	}
}

echo '<table border="1">';
echo '<tr><td>server_info</td><td>' . mysqli_get_server_info($link) . '</td></tr>';
echo '<tr><td>server_version</td><td>' . mysqli_get_server_version($link) . '</td></tr>';
echo '<tr><td>client_info</td><td>' . mysqli_get_client_info($link) . '</td></tr>';
echo '<tr><td>client_version</td><td>' . mysqli_get_client_version($link) . '</td></tr>';
echo '<tr><td>stat</td><td>' . mysqli_stat($link) . '</td></tr>';
echo '</table><br><hr><br>';

// https://mariadb.com/kb/en/mariadb/show-processlist/
$result = mysqli_query($link, 'SHOW FULL PROCESSLIST');
if (!$result) die("Error: " . mysqli_error($link));

echo '<table border="1">';
echo '<tr><th>ID</th><th>USER</th><th>HOST</th><th>DB</th><th>COMMAND</th><th>TIME</th><th>STATE</th><th>INFO</th><th>PROGRESS</th></tr>';
while ($row = mysqli_fetch_row($result))
{
	echo '<tr>';
	for($i = 0; $i < count($row); $i++) echo '<td>' . $row[$i] . '</td>';
	echo '</tr>';
}
echo '</table><br><hr><br>';

// https://mariadb.com/kb/en/mariadb/information-schema-processlist-table/
$result = mysqli_query($link, 'SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST');
if (!$result) die("Error: " . mysqli_error($link));

echo '<table border="1">';
echo '<tr><th>ID</th><th>USER</th><th>HOST</th><th>DB</th><th>COMMAND</th><th>TIME</th><th>STATE</th><th>INFO</th>';
echo '<th>TIME_MS</th><th>STAGE</th><th>MAX_STAGE</th><th>PROGRESS</th><th>MEMORY_USED</th><th>EXAMINED_ROWS</th><th>QUERY_ID</th><th>INFO_BINARY</th>';
echo '<th>TID</th></tr>';
while ($row = mysqli_fetch_row($result))
{
	echo '<tr>';
	for($i = 0; $i < count($row); $i++) echo '<td>' . $row[$i] . '</td>';
	echo '</tr>';
}
echo '</table><br><hr><br>';

echo '</center>';

$result = mysqli_query($link, 'SHOW ENGINE INNODB STATUS');
if (!$result) die("Error: " . mysqli_error($link));
$row = mysqli_fetch_row($result);

echo "<pre>$row[2]</pre><br>\r\n";

EOL

cat > /opt/status/vars.php <<'EOL'
<?php

require 'db.php';

$result = mysqli_query($link, 'SHOW VARIABLES');
if (!$result) die("Error: " . mysqli_error($link));

echo '<center><table border="1">';
while ($row = mysqli_fetch_row($result))
{
	echo '<tr>';
	for($i = 0; $i < count($row); $i++) echo '<td>' . $row[$i] . '</td>';
	echo '</tr>';
}
echo '</table><br></center>';

EOL

cat > /opt/status/status.php <<'EOL'
<?php

require 'db.php';

$result = mysqli_query($link, 'SHOW STATUS');
if (!$result) die("Error: " . mysqli_error($link));

echo '<center><table border="1">';
while ($row = mysqli_fetch_row($result))
{
	echo '<tr>';
	for($i = 0; $i < count($row); $i++) echo '<td>' . $row[$i] . '</td>';
	echo '</tr>';
}
echo '</table><br></center>';

EOL

cat > /opt/status/table.php <<'EOL'
<?php

require 'db.php';

$result = mysqli_query($link, 'SHOW TABLE STATUS');
if (!$result) die("Error: " . mysqli_error($link));

echo '<table border="1">';
echo '<tr><th>Name</th><th>Engine</th><th>Version</th><th>Row_format</th><th>Rows</th><th>Avg_row_length</th><th>Data_length</th><th>Max_data_length</th><th>Index_length</th><th>Data_free</th><th>Auto_increment</th><th>Create_time</th><th>Update_time</th><th>Check_time</th><th>Collation</th><th>Checksum</th><th>Create_options</th><th>Comment</th></tr>';
while ($row = mysqli_fetch_row($result))
{
	echo '<tr>';
	for($i = 0; $i < count($row); $i++) echo '<td>' . $row[$i] . '</td>';
	echo '</tr>';
}
echo '</table><br>';

EOL

# Clean up
rm /script_init.sh
exit 0
