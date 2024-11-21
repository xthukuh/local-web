#!/bin/bash

# -------------------------------------------------------------------------------------------------------------------------------
# SETUP SITES | Edit as you wish!
# -------------------------------------------------------------------------------------------------------------------------------
# Command Usage:
#                     setup   [--help|-h] [--name|-n] [--domains|-d] [--public|-p] [--logs|-l] [--ssl|-s] [--ca|-c] [--vhosts|-v]
# Options:
#     --name|-n       *required* Server identifier name (e.g. -n="example").
#     --domains|-d    *required* Server space or comma delimited domain names (e.g. -d="example.com www.example.com example.net").
#     --public|-p     *required* Server public website files root directory (e.g. -p="/etc/www/html/example/public").
#     --logs|-l       *optional* Server access and error logs root directory (e.g. -l="/etc/www/logs").
#     --ssl|-s        *optional* SSL private.key and certificate.pem root directory (e.g. -s="/etc/www/config/ssl/example").
#     --ca|-c         *optional* SSL CA certificate root directory (e.g. -c="/etc/www/config/ca").
#     --vhosts|-v     *optional* Apache VHosts config root directory (e.g. -v="/etc/www/config/vhosts").
#     --help|-h       *optional* Show command usage docs.
# -------------------------------------------------------------------------------------------------------------------------------


# (default) localhost
if [ -d '/etc/www/html/localhost' ]; then
	echo 'Setup localhost...'
	setup -n 'localhost' -d 'localhost local.site' -p '/etc/www/html/localhost'
	echo 'Setup localhost - OK'
fi

# (default) test
if [ -d '/etc/www/html/test' ]; then
	echo 'Setup test...'
	setup -n 'test' -d 'test.site' -p '/etc/www/html/test'
	echo 'Setup test - OK'
fi

# ...