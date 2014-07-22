#!/bin/bash
echo "Pre-requiste is this script should run as root. If you are root user then please enter to continue"
read rt
sudo add-apt-repository ppa:ondrej/php5
apt-get update 
dpkg -l | grep -i php5-fpm || apt-get --force-yes --fix-missing install php5-fpm
dpkg -l | grep -i mysql-server || apt-get --force-yes --fix-missing install mysql-server
dpkg -l | grep -i php5-mysql || apt-get --force-yes --fix-missing install php5-mysql
mysql_install_db
dpkg -l | grep -i nginx || $(apt-get remove --force-yes nginx;apt-get --force-yes --fix-missing install  nginx )
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
grep -v "bind-address" /etc/mysql/my.cnf > /tmp/my.cnf
cp /tmp/my.cnf /etc/mysql/my.cnf
service mysql restart
touch /etc/nginx/sites-available/$dm
ln -s /etc/nginx/sites-available/$dm /etc/nginx/sites-enabled/$dm
mkdir -p /var/www/html/$dm/wordpress
chown www-data.www-data /var/www/html/$dm/wordpress/
cat > /tmp/domain-file<<end
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

cat /tmp/domain-file >  /etc/nginx/sites-available/$dm
chown -R www-data.www-data /var/www/html/$dm
rm  /tmp/domain-file
service nginx restart
cd /var/www/html/$dm/
rm latest.tar.gz
wget https://wordpress.org/latest.tar.gz 
tar -xzvf latest.tar.gz
cd -
echo "Enter username for wordpress "
read ur
echo " Enter password for wordpress user $ur"
read ps
echo " Enter password for wordpress database"
read dps
echo "Enter your email address "
read email
echo "Enter username of mysql server"
read u
echo "Enter password of mysql server"
read p
cat > grant.sql<<end
use mysql;
create user 'wordpress'@'$dm' identified by '$dps';
grant all on wordpress.* to 'wordpress'@'$dm';
end
mysql -u $u -p$p < grant.sql 
mysql --host=$dm -u wordpress  -p$dps < wordpress.sql
year=`date +%Y`
month=`date +%m`
day=`date +%d`
time=`date +%H:%M:%S`

cat > /tmp/wordpress2.sql<<end
use wordpress;
delete  from wp_users;
insert into wp_users values('','$ur',password('$ps'),'$ur','$email','',' '$year-$month-$day $time','',0,'$ur');
end 
mysql --host=$dm -u wordpress -p$dps  < /tmp/wordpress2.sql
touch /tmp/wp-config.php
sudo cat > /tmp/wp-config.php<<end
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', 'wordpress');
define('DB_PASSWORD', '$dps');
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
\$table_prefix  = 'wp_';
define('WPLANG', '');
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');
require_once(ABSPATH . 'wp-settings.php');
end

sudo cp /tmp/wp-config.php /var/www/html/$dm/wordpress/.
chown -R www-data.www-data /var/www/html/$dm/wordpress/
rm /tmp/wp-config.php
rm /tmp/wordpress2.sql
rm grant.sql




