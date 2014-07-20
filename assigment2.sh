#!/bin/bash

dpkg -l | grep -i php5-fpm || apt-get --force-yes install php5-fpm
dpkg -l | grep -i mysql-server || apt-get --force-yes  install mysql-server
dpkg -l | grep -i php5-mysql || apt-get --force-yes install php5-mysql
sudo mysql_install_db
dpkg -l | grep -i nginx || $(apt-get remove --force-yes nginx;apt-get install nginx )
grep -v "cgi.fix_path=0" /etc/php5/fpm/php.ini > /tmp/php.ini
echo "cgi.fix_path=1" >> /tmp/php.ini
cp -f /tmp/php.ini /etc/php5/fpm/php.ini
rm -f /tmp/php.ini
grep -v "listen = 127.0.0.1:9000" /etc/php5/fpm/pool.d/www.conf > /tmp/www.conf
echo "listen = /var/run/php5-fpm.sock" >> /tmp/www.conf
cp -f /tmp/www.conf /etc/php5/fpm/www.conf
rm /tmp/www.conf
################# domain for nginx and /etc/hosts entry###############
echo " Please enter domain name : "
read dm
echo "Please enter IP for given domain name: "
read ip

echo "$ip $dm">> /etc/hosts
touch /etc/nginx/site-available/$dm
ln -s /etc/nginx/site-available/$dm /etc/nginx/site-enabled/$dm
mkdir -p /var/www/html/$dm/wordpress
chown www-data.www-data /var/www/html/$dm/wordpress/
cat domain-file<<end
server {
	listen $ip:80;


	root /var/www/html/$dm/wordpress/;
	index index.php index.html index.htm;

	
	server_name $dm;

	location / {
		try_files \$uri \$uri/ =404;
	}

	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass unix:/var/run/php5-fpm.sock;
		fastcgi_index index.php;
		include fastcgi_params;
	}

}	
end

cat domain-file >  /etc/nginx/site-available/$dm
chown -R www-data.www-data /var/www/html/$dm

service nginx restart
cd /var/www/html/$dm/wordpress
wget https://wordpress.org/latest.tar.gz 
tar -xzvf latest.tar.gz
echo "Enter username for wordpress "
read ur
echo " Enter password for wordpress "
read ps;
echo "Enter password for database "
read dps
echo "Enter your email address "
read email
cat > grant.sql<<end
create user 'wordpress"@'$dm' identified by '$ps';
grant all on wordpress.* to 'wordpress'@'$dm';
end
mysql < grant.sql 
mysql < wordpress.sql
year=`date +%Y`
month=`date +%m`
day=`date +%d`
time=`date +%H:%M:%S`

cat > wordpress2.sql<<end
use wordpress;
delete * from wp_users;
insert into wp_users values('','$ur',password('$ps'),'$ur','$email','',' '$year-$month-$day $time','',0,'$ur');
end 
mysql -u wordpress -p$ps < wordpress2.sql

cat > wp-config.php<<end
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', '$ur');
define('DB_PASSWORD', '$ps');
define('DB_HOST', '$dm');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
$table_prefix  = 'wp_';
define('WPLANG', '');
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
end
cp wp-config.php /var/www/html/$dm/wordpress/.
chown -R www-data.www-data /var/www/html/$dm/wordpress/
rm wp-config.php
rm wordpress2.sql
rm grant.sql




