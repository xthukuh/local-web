#!/bin/bash

# defaults
_HOME='/etc/www'
_HOME_LOGS="$_HOME/logs"
_HOME_VHOSTS="$_HOME/config/vhosts"
_HOME_SSL="$_HOME/config/ssl"
_HOME_SSL_CA="$_HOME_SSL/ca"

# exit script immediately if any command returns a non-zero (error) status
set -e

# setup command help docs
_setup_help() {
	local text='Server setup utility.'
	text+=$'\n'
	text+=$'\nUsage: setup   [--help|-h] [--name|-n] [--domains|-d] [--public|-p]'
	text+=$'\n               [--logs|-l] [--ssl|-s] [--ca|-c] [--vhosts|-v]'
	text+=$'\nOptions:'
	text+=$'\n    --name|-n       *required* Server identifier name (e.g. -n="example").'
	text+=$'\n    --domains|-d    *required* Server space or comma delimited domain names (e.g. -d="example.com www.example.com example.net").'
	text+=$'\n    --public|-p     *required* Server public website files root directory (e.g. -p="/etc/www/html/example/public").'
	text+=$'\n    --logs|-l       *optional* Server access and error logs root directory (e.g. -l="/etc/www/logs").'
	text+=$'\n    --ssl|-s        *optional* SSL private.key and certificate.pem root directory (e.g. -s="/etc/www/config/ssl/example").'
	text+=$'\n    --ca|-c         *optional* SSL CA certificate root directory (e.g. -c="/etc/www/config/ca").'
	text+=$'\n    --vhosts|-v     *optional* Apache VHosts config root directory (e.g. -v="/etc/www/config/vhosts").'
	text+=$'\n    --help|-h       *optional* Show command usage docs.'
	text+=$'\n'
	while IFS= read -r line; do
		echo "$line"
	done <<< "$text" 
}

# setup init options
setup_name=""
setup_domain_csv=""
setup_public=""
setup_logs=""
setup_ssl=""
setup_ca=""
setup_vhosts=""

# setup parse arguments
if [ $# -eq 0 ]; then
	echo "$(_setup_help)"$'\n' >&2
	exit 1
fi
while [[ "$#" -gt 0 ]]; do
	case $1 in
		
		# --help
		--help|-h)
			_setup_help
			exit 0
			;;

		# --name
		--name=*|-n=*)
			setup_name="${1#*=}" # extract value after '='
			;;
		--name|-n)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_name="$1"
			else
				setup_name=""
			fi
			;;
			
		# --domains
		--domains=*|-d=*)
			setup_domain_csv="${1#*=}" # extract value after '='
			;;
		--domains|-d)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_domain_csv="$1"
			else
				setup_domain_csv=""
			fi
			;;

		# --public
		--public=*|-p=*)
			setup_public="${1#*=}" # extract value after '='
			;;
		--public|-p)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_public="$1"
			else
				setup_public=""
			fi
			;;

		# --logs
		--logs=*|-l=*)
			setup_logs="${1#*=}" # extract value after '='
			;;
		--logs|-l)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_logs="$1"
			else
				setup_logs=""
			fi
			;;

		# --ssl
		--ssl=*|-s=*)
			setup_ssl="${1#*=}" # extract value after '='
			;;
		--ssl|-s)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_ssl="$1"
			else
				setup_ssl=""
			fi
			;;
			
		# --ca
		--ca=*|-c=*)
			setup_ca="${1#*=}" # extract value after '='
			;;
		--ca|-c)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_ca="$1"
			else
				setup_ca=""
			fi
			;;

		# --vhosts
		--vhosts=*|-v=*)
			setup_vhosts="${1#*=}" # extract value after '='
			;;
		--vhosts|-v)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				setup_vhosts="$1"
			else
				setup_vhosts=""
			fi
			;;

		# default
		*)
			echo "[-] Unsupported option: [$1]" >&2
			echo "$(_setup_help)"$'\n' >&2
			exit 1
			;;
	esac
	shift # shift to the next argument
done

# helper - get identifier name
_get_identifier_name() {
	local name=$(echo "$1" | xargs) # trim spaces
	if [ -z "$name" ]; then
		echo '[-] Setup server identifier name option [--name|-n] value is required.' >&2
		return 1
	fi
	local regex='^[a-zA-Z0-9]+[a-zA-Z0-9._-]*[a-zA-Z0-9]+$' # identifier name regex
	if [[ ! $name =~ $regex ]]; then
		echo "[-] Setup server identifier name option [--name|-n] value \"$name\" is invalid." >&2
		return 1
	fi
	echo "$name" # result - valid identifier name
}

# setup get domain names csv
_setup_get_domain_csv() {
	local input="$1"
	if [ -z "$input" ]; then
		echo '[-] Setup server domain names option [--domains|-d] value is required.' >&2
		return 1
	fi
	local regex='^([a-zA-Z0-9](-?[a-zA-Z0-9])*\.?)+[a-zA-Z]{2,}$' # domain name regex
	local buffer=""
	local value=""
	declare -A seen
	for value in $input; do
		value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') # trim whitespace
		if [[ -z "${seen[$value]}" && -n "$value" ]]; then # skip duplicate
			if [[ ! $value =~ $regex ]]; then # validate domain name
				echo "[-] Found an invalid domain name \"$value\" in setup server domain names option [--domains|-d] value \"$input\"." >&2
				return 1
			fi
			if [ -z "$buffer" ]; then
				buffer="$value" # buffer add value
			else
				buffer="$buffer,$value" # buffer add csv value
			fi
			seen[$value]=1 # value as seen
		fi
	done
	if [ -z "$buffer" ]; then
		echo '[-] Setup server domain names option [--domains|-d] value is required.' >&2
		return 1
	fi
	echo "$buffer" # result - valid domain names csv
}

# helper - get valid path
# # Usage: _get_valid_path [path] [label]
# $ setup_public=$(_get_valid_path "$setup_public" "The path value")
_get_valid_path() {
	local path=$(echo "$1" | xargs) # trim spaces
	local label=$(echo "$2" | xargs) # trim spaces
	if [ -z "$path" ]; then
		echo "[-] $label is required." >&2
		return 1
	fi
	if [ -z "$label" ]; then
		label="The path value"
	fi
	local regex='^([a-zA-Z0-9_./-]+)$' # path regex
	if [[ ! $path =~ $regex ]]; then
		echo "[-] $label \"$path\" has invalid characters." >&2
		return 1
	fi
	echo "$path" # result - valid path
}

# helper - get existing directory path (create if not exists)
_get_existing_dir() {
	local path=$(echo "$1" | xargs) # trim spaces
	local label=$(echo "$2" | xargs) # trim spaces
	if [ -z "$path" ]; then
		echo "[-] Invalid blank $label directory path." >&2
		return 1
	fi
	if [ "$path" != "/" ]; then
		path="${path%/}" # trim the trailing slash
	fi
	if [ ! -d "$path" ]; then
		mkdir -p "$path" > /dev/null 2>&1
		if [ ! -d "$path" ]; then
			echo "[-] Failed to create $label directory: \"$path\"" >&2
			return 1
		fi
	fi
	echo "$path" # result - existing directory path
}

# parse --name
setup_name=$(_get_identifier_name "$setup_name")

# parse --domains
setup_domain_csv=$(_setup_get_domain_csv "$setup_domain_csv")

# parse --public
setup_public=$(_get_valid_path "$setup_public" "Setup server public website files root directory option [--public|-p] value")

# parse --logs
setup_logs=$(echo "$setup_logs" | xargs) # trim spaces
if [ -n "$setup_logs" ]; then
	setup_logs=$(_get_valid_path "$setup_logs" "Setup server access and error logs root directory option [--logs|-l] value")
else
	setup_logs="$_HOME_LOGS"
fi

# parse --ssl
setup_ssl=$(echo "$setup_ssl" | xargs) # trim spaces
if [ -n "$setup_ssl" ]; then
	setup_ssl=$(_get_valid_path "$setup_ssl" "Setup server private key and certificate root directory option [--ssl|-s] value")
else
	setup_ssl="$_HOME_SSL/$setup_name"
fi

# parse --ca
setup_ca=$(echo "$setup_ca" | xargs) # trim spaces
if [ -n "$setup_ca" ]; then
	setup_ca=$(_get_valid_path "$setup_ca" "Setup SSL CA certificate root directory option [--ca|-c] value")
else
	setup_ca="$_HOME_SSL_CA"
fi

# parse --vhosts
setup_vhosts=$(echo "$setup_vhosts" | xargs) # trim spaces
if [ -n "$setup_vhosts" ]; then
	setup_vhosts=$(_get_valid_path "$setup_vhosts" "Setup Apache VHosts config root directory option [--vhosts|-v] value")
else
	setup_vhosts="$_HOME_VHOSTS"
fi

# setup config
setup_vhost_conf="$setup_vhosts/$setup_name.conf"
setup_vhost_conf_ssl="$setup_vhosts/$setup_name-ssl.conf"
setup_ServerName=""
setup_ServerAlias=""
IFS=',' read -ra domain_array <<< "$setup_domain_csv"
for domain in "${domain_array[@]}"; do
	if [ -z "$setup_ServerName" ]; then
		setup_ServerName="$domain"
	else
		if [ -z "$setup_ServerAlias" ]; then
			setup_ServerAlias="$domain"
		else
			setup_ServerAlias="$setup_ServerAlias $domain"
		fi
	fi
done
setup_DocumentRoot="$setup_public"
setup_ErrorLog="$setup_logs/$setup_name-error.log"
setup_AccessLog="$setup_logs/$setup_name-access.log"
setup_SSLCertificateFile="$setup_ssl/certificate.pem"
setup_SSLCertificateKeyFile="$setup_ssl/private.key"
setup_SSLCACertificateFile="$setup_ca/certificate_authority.pem"

# setup certificates
echo "[~] Setup \"$setup_name\" self-signed certificates...";
if ! selfsign certificate -d "$setup_domain_csv" -s "$setup_ssl" -c "$setup_ca"; then
	echo "[~] Failed to generate \"$setup_name\" self-signed certificates." >&2;
	exit 1
fi

# setup vhosts
echo "[~] Setup \"$setup_name\" virtual host files...";

# setup vhosts - root
setup_vhosts=$(_get_existing_dir "$setup_vhosts")
if [ ! -d "$setup_vhosts" ]; then
	echo "[-] Failed to create vhosts directory ($setup_vhosts)." >&2
	exit 1
fi

# setup vhosts - server alias text
setup_server_alias_text=""
	if [ -n "$setup_ServerAlias" ]; then
		setup_server_alias_text="
    # other domain names server responds to
    ServerAlias $setup_ServerAlias
"
	fi

# setup vhosts - setup_vhost_conf
if [ ! -f "$setup_vhost_conf" ]; then
	cat << EOF > "$setup_vhost_conf"
<VirtualHost *:80>
    # server domain name
    ServerName $setup_ServerName
$setup_server_alias_text
    # site code directory
    DocumentRoot "$setup_DocumentRoot"

    # accept php and html files as directory index
    DirectoryIndex index.php index.html

    # access and error logs
    ErrorLog "$setup_ErrorLog"
    CustomLog "$setup_AccessLog" combined

    # custom error log format
    ErrorLogFormat "[%t] [%l] [client %a] %M, referer: %{Referer}i"

    # log 404 as errors
    LogLevel core:info

    # set which file apache will serve when url is a directory
    DirectoryIndex index.html index.php

    # fix http basic authentication
    SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=\$1

    # configure site code directory
    <Directory "$setup_DocumentRoot">
        # Normally, if multiple Options could apply to a directory, then the most specific one is used and others are ignored; the options are not merged. (See how sections are merged.)
        # However if all the options on the Options directive are preceded by a + or - symbol, the options are merged.
        # Any options preceded by a + are added to the options currently in force, and any options preceded by a - are removed from the options currently in force.
        Options -ExecCGI +FollowSymLinks -SymLinksIfOwnerMatch -Includes -IncludesNOEXEC -Indexes -MultiViews

        # define what Options directives can be overriden in .htaccess
        AllowOverride All Options=ExecCGI,Includes,IncludesNOEXEC,Indexes,MultiViews,SymLinksIfOwnerMatch

        # set who can access the directory
        Require all granted
    </Directory>

    # file php extension handled by php-fpm
    <FilesMatch "\.php$">
        SetHandler "proxy:unix:/var/run/php-fpm8.sock|fcgi://localhost"
    </FilesMatch>
</VirtualHost>
EOF
echo "[+] File created: \"$setup_vhost_conf\""
else
	echo "[+] File exists: \"$setup_vhost_conf\""
fi

# setup vhosts - setup_vhost_conf_ssl
if [ ! -f "$setup_vhost_conf_ssl" ]; then
	cat << EOF > "$setup_vhost_conf_ssl"
<VirtualHost *:443>
    # server domain name
    ServerName $setup_ServerName
$setup_server_alias_text
    # site code directory
    DocumentRoot "$setup_DocumentRoot"

    # accept php and html files as directory index
    DirectoryIndex index.php index.html

    # access and error logs
    ErrorLog "$setup_ErrorLog"
    CustomLog "$setup_AccessLog" combined

    # custom error log format
    ErrorLogFormat "[%t] [%l] [client %a] %M, referer: %{Referer}i"

    # log 404 as errors
    LogLevel core:info

    # set which file apache will serve when url is a directory
    DirectoryIndex index.html index.php

    # fix http basic authentication
    SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=\$1

    # configure site code directory
    <Directory "$setup_DocumentRoot">
        # Normally, if multiple Options could apply to a directory, then the most specific one is used and others are ignored; the options are not merged. (See how sections are merged.)
        # However if all the options on the Options directive are preceded by a + or - symbol, the options are merged.
        # Any options preceded by a + are added to the options currently in force, and any options preceded by a - are removed from the options currently in force.
        Options -ExecCGI +FollowSymLinks -SymLinksIfOwnerMatch -Includes -IncludesNOEXEC -Indexes -MultiViews

        # define what Options directives can be overriden in .htaccess
        AllowOverride All Options=ExecCGI,Includes,IncludesNOEXEC,Indexes,MultiViews,SymLinksIfOwnerMatch

        # set who can access the directory
        Require all granted
    </Directory>

    # file php extension handled by php-fpm
    <FilesMatch "\.php$">
        SetHandler "proxy:unix:/var/run/php-fpm8.sock|fcgi://localhost"
    </FilesMatch>

    # use SSL
    SSLEngine On

    # certificates
    SSLCertificateFile "$setup_SSLCertificateFile"
    SSLCertificateKeyFile "$setup_SSLCertificateKeyFile"
    SSLCACertificateFile "$setup_SSLCACertificateFile"
</VirtualHost>
EOF
	echo "[+] File created: \"$setup_vhost_conf_ssl\""
else
	echo "[+] File exists: \"$setup_vhost_conf_ssl\""
fi

# --- test
## ./setup -n "test" -d "test.com www.test.com" -p "/etc/www/html/test" -l "/etc/www/logs" -s "/etc/www/config/ssl" -c "/etc/www/config/ssl/ca" -v "/etc/www/config/vhosts"
# ./setup -n "test" -d "test.com www.test.com" -p "/etc/www/html/test"
# ./setup -n "localhost" -d "localhost local.site" -p "/etc/www/html/localhost"
