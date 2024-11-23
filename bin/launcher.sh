#!/bin/bash

echo ''
echo 'Start container web server...'

# -------------------------------------------------------
# Docker entry point script
# -------------------------------------------------------

# exit script immediately if any command returns a non-zero (error) status
# set -e

# check if we should expose apache/php to host
# /docker/etc/ must be set in docker-compose.yml
if [ -d /docker/etc/ ]; then

	# ------------- expose apache
	echo 'Expose apache to host...'
	sleep 1

	# create config backup if not exist
	if [ ! -d /etc/apache2.bak/ ]; then
		echo 'Expose apache to host - backup container config'
		cp -r /etc/apache2/ /etc/apache2.bak/
	fi

	# create config on host if not exists
	if [ -z "$(ls -A /docker/etc/apache2/ 2> /dev/null)" ]; then
		echo 'Expose apache to host - no host config'
		
		# restore config from backup if exists
		if [ -d /etc/apache2.bak/ ]; then
			echo 'Expose apache to host - restore config from backup'
			rm /etc/apache2/ 2> /dev/null
			if [ -d /etc/apache2/ ]; then
				cp -r /etc/apache2.bak/* /etc/apache2/
			else
				cp -r /etc/apache2.bak/ /etc/apache2/
			fi
		fi

		# copy config to host
		echo 'Expose apache to host - copy config to host'
		cp -r /etc/apache2/ /docker/etc/
	else
		echo 'Expose apache to host - config exists on host'
	fi

	# create symbolic link so host config is used
	echo 'Expose apache to host - create symlink'
	rm -rf /etc/apache2/ 2> /dev/null
	ln -s /docker/etc/apache2 /etc/apache2
	echo 'Expose apache to host - OK'
	
	# ------------- expose php
	echo 'Expose php to host...'
	sleep 1

	# create config backup if not exist
	if [ ! -d /etc/php83.bak/ ]; then
		echo 'Expose php to host - backup container config'
		cp -r /etc/php83/ /etc/php83.bak/
	fi

	# create config on host if not exist
	if [ -z "$(ls -A /docker/etc/php83/ 2> /dev/null)" ]; then
		echo 'Expose php to host - no host config'
		
		# restore config from backup if exists
		if [ -d /etc/php83.bak/ ]; then
			echo 'Expose php to host - restore config from backup'
			rm /etc/php83/ 2> /dev/null
			if [ -d /etc/php8/ ]; then
				cp -r /etc/php83.bak/* /etc/php8/
			else
				cp -r /etc/php83.bak/ /etc/php8/
			fi
		fi

		# copy config to host
		echo 'Expose php to host - copy config to host'
		cp -r /etc/php83/ /docker/etc/
	else
		echo 'Expose php to host - config exists on host'
	fi

	# create symbolic link so host config is used
	echo 'Expose php to host - create symlink'
	rm -rf /etc/php83/ 2> /dev/null
	ln -s /docker/etc/php83 /etc/php83
	echo 'Expose php to host - OK'
fi

# docker-compose.yml mounts ./www dir on host
# create www defaults if not exist (on first /etc/www/config load)
if [ ! -d /etc/www/config/ ]; then
	echo 'Copy www defaults....'

	# config
	# mkdir -p /etc/www/config/
	cp -r /etc/www.bak/config/ /etc/www/config/

	# logs
	if [ ! -d /etc/www/logs/ ]; then
		cp -r /etc/www.bak/logs/ /etc/www/logs/
	fi

	# html
	if [ ! -d /etc/www/html/ ]; then
		# mkdir -p /etc/www/html/
		cp -r /etc/www.bak/html/ /etc/www/html/
	fi

	# html/localhost
	if [ ! -d /etc/www/html/localhost/ ]; then
		cp -rp /etc/www.bak/html/localhost/ /etc/www/html/localhost/
	fi

	# html/test
	if [ ! -d /etc/www/html/test/ ]; then
		cp -rp /etc/www.bak/html/test/ /etc/www/html/test/
	fi

	echo 'Copy www defaults - OK'
fi

# check if SSL certificate authority does not exist
# https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate
if [ ! -e /etc/www/config/ssl/ca/certificate_authority.pem ]; then
	echo 'Generate SSL certificate authority...'
	selfsign authority -c /etc/www/config/ssl/ca
	echo 'Generate SSL certificate authority - OK'
fi

# setup local sites ~ /etc/www/config/sites.sh
echo 'Setup local sites....'
if [ ! -f /etc/www/config/sites.sh ]; then
	cp -p /etc/www.bak/config/sites.sh /etc/www/config/sites.sh
	if [ ! -f /etc/www/config/sites.sh ]; then
		echo '[!] File not found: /etc/www/config/sites.sh' >&2
		exit 1
	fi
fi
source /etc/www/config/sites.sh
echo 'Setup local sites - OK'

# clean log files
echo 'Clean log files...'

# truncate - logs/*-access.log
for log_file in /etc/www/logs/*-access.log; do
	if [[ -f "$log_file" ]]; then
		truncate -s 0 "$log_file" 2> /dev/null
	fi
done

# truncate - logs/*-error.log
for log_file in /etc/www/logs/*-error.log; do
	if [[ -f "$log_file" ]]; then
		truncate -s 0 "$log_file" 2> /dev/null
	fi
done

# truncate - logs/xdebug.log
if [ -f '/etc/www/logs/xdebug.log' ]; then
	truncate -s 0 /etc/www/logs/xdebug.log 2> /dev/null
fi

# truncate - /var/log/ssl_request.log
if [ -f '/var/log/ssl_request.log' ]; then
	truncate -s 0 /var/log/ssl_request.log 2> /dev/null
fi

echo 'Clean log files - OK'

# allow xdebug to write to log file
if [ -f '/var/log/xdebug.log' ]; then
	chmod 666 /var/log/xdebug.log 2> /dev/null
fi

# start php-fpm
echo 'Start php-fpm...'
php-fpm83

# sleep
sleep 1

# check if php-fpm is running
if pgrep -x php-fpm83 > /dev/null; then
	echo 'Start php-fpm - OK'
else
	echo 'Start php-fpm - FAILED'
	exit 1
fi

echo '-------------------------------------------------------'

# start apache
httpd -k start

# check if apache is running
if pgrep -x httpd > /dev/null; then
	echo 'Start container web server - OK - ready for connections'
else
	echo 'Start container web server - FAILED'
	exit 1
fi

echo '-------------------------------------------------------'

stop_container()
{
	echo ''
	echo 'Stop container web server... - received SIGTERM signal'
	echo 'Stop container web server - OK'
	exit 0
}

# catch termination signals
# https://unix.stackexchange.com/questions/317492/list-of-kill-signals
trap stop_container SIGTERM

restart_processes()
{
	sleep 0.5

	# test php-fpm config
	if php-fpm83 -t; then
		
		# restart php-fpm
		echo 'Restart php-fpm...'
		killall php-fpm83 > /dev/null
		php-fpm83

		# check if php-fpm is running
		if pgrep -x php-fpm83 > /dev/null; then
			echo 'Restart php-fpm - OK'
		else
			echo 'Restart php-fpm - FAILED'
		fi
	else
		echo 'Restart php-fpm - FAILED - syntax error'
	fi

	# test apache config
	if httpd -t; then
		
		# restart apache
		echo 'Restart apache...'
		httpd -k restart

		# check if apache is running
		if pgrep -x httpd > /dev/null; then
			echo 'Restart apache - OK'
		else
			echo 'Restart apache - FAILED'
		fi
	else
		echo 'Restart apache - FAILED - syntax error'
	fi
}

# infinite loop, will only stop on termination signal or deletion of /etc/www/config
while [ -d /etc/www/config/ ]; do
	
	# restart apache and php-fpm if any file in /etc/apache2 or /etc/php83 changes
	inotifywait --quiet \
		--event modify,create,delete \
		--timeout 3 \
		--recursive /etc/apache2/ /etc/php83/ /etc/www/config/ssl/ /etc/www/config/vhosts/ \
		&& restart_processes
done
