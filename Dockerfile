# https://hub.docker.com/_/alpine
# don't use alpine:edge as it is not refreshed that often
# FROM alpine:latest
FROM alpine:3.20
LABEL maintainer="Thuku <https://github.com/xthukuh>"

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

# update and upgrade repositories
RUN printf "https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\n" > /etc/apk/repositories
RUN apk update
RUN apk upgrade

# add bash
RUN apk add bash

# make bash the default shell
RUN sed -i 's|/bin/ash|/bin/bash|' /etc/passwd

# add tini https://github.com/krallin/tini/issues/8
RUN apk add tini

# install latest certificates for ssl
RUN apk add ca-certificates

# install console tools
RUN apk add inotify-tools

# install and configure zsh
RUN apk add zsh zsh-vcs
COPY --chown=root:root bin/zshrc /etc/zsh/zshrc

# install php
RUN apk add \
  php83 \
  # php83-apache2 \
  php83-bcmath \
  # php83-brotli \
  php83-bz2 \
  php83-calendar \
  # php83-cgi \
  php83-common \
  php83-ctype \
  php83-curl \
  # php83-dba \
  # php83-dbg \
  # php83-dev \
  # php83-doc \
  php83-dom \
  # php83-embed \
  # php83-enchant \
  php83-exif \
  # php83-ffi \
  php83-fileinfo \
  php83-ftp \
  php83-gd \
  php83-gettext \
  # php83-gmp \
  php83-json \
  php83-iconv \
  php83-imap \
  php83-intl \
  php83-ldap \
  # php83-litespeed \
  php83-mbstring \
  php83-mysqli \
  # php83-mysqlnd \
  # php83-odbc \
  php83-opcache \
  php83-openssl \
  php83-pcntl \
  php83-pdo \
  php83-pdo_mysql \
  # php83-pdo_odbc \
  # php83-pdo_pgsql \
  php83-pdo_sqlite \
  # php83-pear \
  # php83-pgsql \
  php83-phar \
  # php83-phpdbg \
  php83-posix \
  # php83-pspell \
  php83-session \
  # php83-shmop \
  php83-simplexml \
  # php83-snmp \
  # php83-soap \+
  # php83-sockets \
  php83-sodium \
  php83-sqlite3 \
  # php83-sysvmsg \
  # php83-sysvsem \
  # php83-sysvshm \
  # php83-tideways_xhprof \
  # php83-tidy \
  php83-tokenizer \
  php83-xml \
  php83-xmlreader \
  php83-xmlwriter \
  php83-zip

# use php83-fpm instead of php83-apache
RUN apk add php83-fpm

# i18n
RUN apk add icu-data-full

# fix php iconv
# https://stackoverflow.com/questions/70046717/iconv-error-when-running-statamic-laravel-seo-pro-plugin-with-phpfpm-alpine
# iconv(): Wrong encoding, conversion from &quot;UTF-8&quot; to &quot;UTF-8//IGNORE&quot; is not allowed
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# create php aliases
# RUN ln -s /usr/bin/php84 /usr/bin/php
RUN ln -s /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# PECL extensions
# RUN apk add \
  # php83-pecl-amqp \
  # php83-pecl-apcu \
  # php83-pecl-ast \
  # php83-pecl-couchbase \
  # php83-pecl-event \
  # php83-pecl-igbinary \
  # php83-pecl-imagick \
  # php83-pecl-imagick-dev \
  # php83-pecl-lzf \
  # php83-pecl-mailparse \
  # php83-pecl-maxminddb \
  # php83-pecl-mcrypt \
  # php83-pecl-memcache \
  # php83-pecl-memcached \
  # php83-pecl-mongodb \
  # php83-pecl-msgpack \
  # php83-pecl-oauth \
  # php83-pecl-protobuf \
  # php83-pecl-psr \
  # php83-pecl-rdkafka \
  # php83-pecl-redis \
  # php83-pecl-ssh2 \
  # php83-pecl-timezonedb \
  # php83-pecl-uploadprogress \
  # php83-pecl-uploadprogress-doc \
  # php83-pecl-uuid \
  # php83-pecl-vips \
  # php83-pecl-xdebug \
  # php83-pecl-xhprof \
  # php83-pecl-xhprof-assets \
  # php83-pecl-yaml \
  # php83-pecl-zstd \
  # php83-pecl-zstd-dev

# configure xdebug
# COPY --chown=root:root bin/xdebug.ini /etc/php83/conf.d/xdebug.ini

# setup composer
COPY --chown=root:root bin/composer.sh /tmp/composer.sh
RUN chmod +x /tmp/composer.sh
RUN /tmp/composer.sh
RUN mv /composer.phar /usr/bin/composer

# setup selfsign.sh
COPY --chown=root:root bin/selfsign.sh /usr/bin/selfsign
RUN chmod +x /usr/bin/selfsign

# setup setup.sh
COPY --chown=root:root bin/setup.sh /usr/bin/setup
RUN chmod +x /usr/bin/setup

# install apache
RUN apk add apache2 apache2-ssl apache2-proxy

# delete apk cache
RUN rm -rf /var/cache/apk/*

# add user www-data
# group www-data already exists
# -H don't create home directory
# -D don't assign a password
# -S create a system user
RUN adduser -H -D -S -G www-data -s /sbin/nologin www-data

# copy backup httpd.conf
RUN cp /etc/apache2/httpd.conf /etc/apache2/httpd.bak.conf

# update user and group apache runs under
RUN sed -i 's|User apache|User www-data|g' /etc/apache2/httpd.conf
RUN sed -i 's|Group apache|Group www-data|g' /etc/apache2/httpd.conf

# enable mod rewrite (rewrite urls in htaccess)
RUN sed -i 's|#LoadModule rewrite_module modules/mod_rewrite.so|LoadModule rewrite_module modules/mod_rewrite.so|g' /etc/apache2/httpd.conf

# enable important apache modules
RUN sed -i 's|#LoadModule deflate_module modules/mod_deflate.so|LoadModule deflate_module modules/mod_deflate.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule expires_module modules/mod_expires.so|LoadModule expires_module modules/mod_expires.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule ext_filter_module modules/mod_ext_filter.so|LoadModule ext_filter_module modules/mod_ext_filter.so|g' /etc/apache2/httpd.conf

# switch from mpm_prefork to mpm_event
RUN sed -i 's|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|g' /etc/apache2/httpd.conf

# authorize all directives in .htaccess
RUN sed -i 's|    AllowOverride None|    AllowOverride All|g' /etc/apache2/httpd.conf

# authorize all changes from htaccess
RUN sed -i 's|Options Indexes FollowSymLinks|Options All|g' /etc/apache2/httpd.conf

# configure php-fpm to run as www-data
RUN sed -i 's|user = nobody|user = www-data|g' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|group = nobody|group = www-data|g' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php83/php-fpm.d/www.conf

# configure php-fpm to use unix socket
RUN sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php83/php-fpm.d/www.conf

# update apache timeout for easier debugging
RUN sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf

# add vhosts to apache
RUN echo -e "\n# Include the virtual host configurations:\nIncludeOptional /etc/www/config/vhosts/*.conf" >> /etc/apache2/httpd.conf

# set localhost server name
RUN sed -i "s|#ServerName .*:80|ServerName localhost:80|g" /etc/apache2/httpd.conf

# update php max execution time for easier debugging
RUN sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php83/php.ini

# php log everything
RUN sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php83/php.ini

# add php-spx (https://github.com/NoiseByNorthwest/php-spx)
COPY --chown=root:root bin/php-spx/assets/ /usr/share/misc/php-spx/assets/
COPY --chown=root:root bin/php-spx/spx.so /usr/lib/php83/modules/spx.so
COPY --chown=root:root bin/php-spx/spx.ini /etc/php83/conf.d/spx.ini

# setup entry point script - launcher.sh
COPY --chown=root:root bin/launcher.sh /tmp/launcher.sh
RUN chmod +x /tmp/launcher.sh

# add default www
COPY --chown=www-data:www-data bin/www/ /etc/www.bak/

# set working dir
RUN mkdir -p /etc/www/
RUN chown www-data:www-data /etc/www/
WORKDIR /etc/www/

# set entrypoint
ENTRYPOINT ["tini", "-vw"]

# run script
CMD ["/tmp/launcher.sh"]