#!/bin/bash

# defaults
_CONFIG_SSL_CA='/etc/www/config/ssl/ca'

# selfsign info
declare -Ag _SELFSIGN_SUBJ=(
	['/C']='KE'                           # Country Name (2 letter code) [AU]:
	['/ST']='Nairobi'                     # State or Province Name (full name) [Some-State]:
	['/L']='Nairobi'                      # Locality Name (eg, city) []:
	['/O']='__For Local Development'      # Organization Name (eg, company) [Internet Widgits Pty Ltd]:
	['/OU']='local-web'                   # Organizational Unit Name (eg, section) []:
	['/CN']=''                            # Common Name (e.g. server FQDN or YOUR name) []: example.com
	['/emailAddress']='admin@local.site'  # /emailAddress - email address
)

# _SELFSIGN_SUBJ ordered props
declare -g _SELFSIGN_SUBJ_KEYS=(
	'/C'
	'/ST'
	'/L'
	'/O'
	'/OU'
	'/CN'
	'/emailAddress'
)

# exit script immediately if any command returns a non-zero (error) status
set -e

# selfsign command help docs
_selfsign_help() {
	echo 'Self-signed certificate utils.'
	echo ''
	echo 'Usage:  selfsign [MODE] [OPTIONS] [--help|-h]'
	echo '        selfsign authority [--ca|-c]'
	echo '        selfsign certificate [--domains|-d] [--ssl|-s] [--ca|-c]'
	echo '        selfsign show [--file|-f]'
	echo '        selfsign expiry [--file|-f]'
	echo '        selfsign verify [--domains|-d] [--ssl|-s] [--ca|-c]'
	echo 'MODE:'
	echo '      authority    Generate CA files in [--ca|-c] directory (overwrites existing).'
	echo '      certificate  Generate self-signed certificate for domain names [--domains|-d]'
	echo '                   in [--ssl|-s] directory using [--ca|-c] certificate file (overwrites existing).'
	echo '      show         Displays certificate file [--file|-f] text details.'
	echo '      expiry       Displays certificate file [--file|-f] expiration date (when expired output is in stderr).'
	echo '      verify       Verifies that all [--ssl|-s] and [--ca|-c] certificate files exist, have not expired'
	echo '                   and certificate.pem was signed using same certificate_authority.pem and domains [--domains|-d] match.'
	echo 'OPTIONS:'
	echo '    --domains|-d   *required* Certificate Space or comma delimited domain names (e.g. -d="example.com www.example.com example.net").'
	echo '    --file|-f      *required* Certificate file path (e.g. -f="/etc/www/config/ssl/example/certificate.pem").'
	echo '    --ssl|-s       *required* SSL private.key and certificate.pem root directory (e.g. -s="/etc/www/config/ssl/example").'
	echo '    --ca|-c        *optional* SSL CA certificate root directory (e.g. -c="/etc/www/config/ssl/ca").'
	echo '    --help|-h      *optional* Show command usage docs.'
	echo ''
}

# selfsign init options
selfsign_mode=""
selfsign_domain_csv=""
selfsign_file=""
selfsign_ssl=""
selfsign_ca=""

# parse arguments
if [ $# -eq 0 ]; then
	echo "$(_selfsign_help)"$'\n' >&2
	exit 1
fi
if [[ ! "$1" =~ ^--?[a-z] ]]; then
	selfsign_mode=$(echo "$1" | xargs) # trim spaces
	shift # shift to the next argument
fi
while [[ "$#" -gt 0 ]]; do
	case $1 in
		
		# --help
		--help|-h)
			_selfsign_help
			exit 0
			;;
			
		# --domains
		--domains=*|-d=*)
			selfsign_domain_csv="${1#*=}" # extract value after '='
			;;
		--domains|-d)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				selfsign_domain_csv="$1"
			else
				selfsign_domain_csv=""
			fi
			;;

		# --file
		--file=*|-f=*)
			selfsign_file="${1#*=}" # extract value after '='
			;;
		--file|-f)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				selfsign_file="$1"
			else
				selfsign_file=""
			fi
			;;

		# --ssl
		--ssl=*|-s=*)
			selfsign_ssl="${1#*=}" # extract value after '='
			;;
		--ssl|-s)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				selfsign_ssl="$1"
			else
				selfsign_ssl=""
			fi
			;;
			
		# --ca
		--ca=*|-c=*)
			selfsign_ca="${1#*=}" # extract value after '='
			;;
		--ca|-c)
			if [[ "$#" -gt 1 && ! "$2" =~ ^--?[a-z] ]]; then # ignore option-like values
				shift # shift to the next argument
				selfsign_ca="$1"
			else
				selfsign_ca=""
			fi
			;;

		# default
		*)
			echo "[-] Unsupported OPTION: [$1]" >&2
			echo "$(_selfsign_help)"$'\n' >&2
			exit 1
			;;
	esac
	shift # shift to the next argument
done

# helper - get valid domain names csv
_get_domains_csv() {
	local domains="$1"
	domains=$(echo "$domains" | tr ',' ' ' | xargs -n1 | sort -u) # replace commas with spaces, trim whitespace, and split into array, sort and remove duplicates
	if [ -z "$domains" ]; then
		echo "[-] Domain names option [--domains|-d] value is required." >&2
		return 1
	fi
	local domain_regex='^([a-zA-Z0-9](-?[a-zA-Z0-9])*\.?)+[a-zA-Z]{2,}$' # domain name regex
	local domain_csv="" # domain names csv buffer
	declare -A seen
	for domain in $domains; do
		if [[ -z "${seen[$domain]}" && -n "$domain" ]]; then # skip duplicate
			if [[ ! $domain =~ $domain_regex ]]; then
				echo "[-] Found an invalid domain name \"$domain\" in option [--domains|-d] value \"$1\"." >&2
				return 1
			fi
			domain_csv+="$domain,"
			seen[$domain]=1 # value as seen
		fi
	done
	if [ -n "$domain_csv" ]; then
		domain_csv=${domain_csv%,} # remove trailing comma
	fi
	if [ -z "$domain_csv" ]; then
		echo "[-] No valid domain names found in option [--domains|-d] value \"$1\"." >&2
		return 1
	fi
	echo "$domain_csv"
}

# helper - get valid path
# # Usage: _get_valid_path [path] [label]
# $ setup_web=$(_get_valid_path "$setup_web" "The path value")
_get_valid_path() {
	local path=$(echo "$1" | xargs) # trim spaces
	local label=$(echo "$2" | xargs) # trim spaces
	if [ -z "$label" ]; then
		label="The path value"
	fi
	if [ -z "$path" ]; then
		echo "[-] $label is required." >&2
		return 1
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
	if [ -n "$label" ]; then
		label="$label "
	fi
	if [ -z "$path" ]; then
		echo "[-] Invalid blank$label directory path." >&2
		return 1
	fi
	if [ "$path" != "/" ]; then
		path="${path%/}" # trim the trailing slash
	fi
	if [ ! -d "$path" ]; then
		mkdir -p "$path" > /dev/null 2>&1
		if [ ! -d "$path" ]; then
			echo "[-] Failed to create$label directory: \"$path\"" >&2
			return 1
		fi
	fi
	echo "$path" # result - existing directory path
}

# create ssl subject from domains
_selfsign_subj() {
	local domain=$(echo "$1" | xargs) # trim spaces
	local list=()
	for key in "${_SELFSIGN_SUBJ_KEYS[@]}"; do
		local value="${_SELFSIGN_SUBJ[$key]}"
		if [ "$key" = "/CN" ]; then
			if [ -n "$domain" ]; then
				value="$domain"
			else
				continue
			fi
		fi
		list+=("$key=$value")
	done
	IFS=""
	echo "${list[*]}"
}

# -------------------------------------------------------
# Show certificate
# ~ _selfsign_show [--file]
# -------------------------------------------------------
_selfsign_show() {
	local cert_file="$1"
	if ! openssl x509 -in "$cert_file" -text -noout 2> /dev/null; then
		echo "[-] Show certificate failed! \"$cert_file\"" >&2
		return 1
	fi
}

# -------------------------------------------------------
# Check certificate expiry
# ~ _selfsign_expiry [--file]
# -------------------------------------------------------
_selfsign_expiry() {
	local cert_file="$1"
	local end_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2) # get expiry date
	if [ -z "$end_date" ]; then
		echo "[-] Get certificate expiry date failed! \"$cert_file\"" >&2
		return 1
	fi
	local end_timestamp=$(date -d "$end_date" +%s) # convert the expiration date to a timestamp
	local current_timestamp=$(date +%s) # Get the current timestamp
	local norm_end_date=$(echo "$end_date" | sed 's/  */ /g') # normalize single spacing
	if [ $current_timestamp -gt $end_timestamp ]; then
		echo "$norm_end_date" >&2
		return 1
	else
		echo "$norm_end_date"
	fi
}

# -------------------------------------------------------
# Check certificate domains match
# ~ _selfsign_cert_domains [--file] [--domains]
# -------------------------------------------------------
_selfsign_cert_domains() {
	local cert_file="$1"
	local domains="$2"
	local cert_domains=$(openssl x509 -in "$cert_file" -noout -text \
		| grep -A1 "Subject Alternative Name" \
		| tail -n1 \
		| sed 's/DNS://g' \
		| tr ',' '\n' \
		| tr -d ' ' 2> /dev/null) # extract SANs from the certificate
	if [ -z "$cert_domains" ]; then
		echo "[-] Failed to get SANs from certificate file: \"$cert_file\"." >&2
		return 1
	fi
	domains=$(echo "$domains" | tr ',' '\n' | xargs -n1 | sort -u) # replace commas with newlines, normalize input, and remove duplicates

	# check each domain in the list against the certificate
	local missing_domains=()
	for domain in $domains; do
		if ! echo "$cert_domains" | grep -q "^$domain$"; then
			missing_domains+=("$domain")
		fi
	done

	# find domains in the certificate that are not in the argument
	local extra_domains=()
	for domain in $cert_domains; do
		if ! echo "$domains" | grep -q "^$domain$"; then
			extra_domains+=("$domain")
		fi
	done

	# result
	if [ ${#missing_domains[@]} -eq 0 ] && [ ${#extra_domains[@]} -eq 0 ]; then
		echo "[+] Certificate matches the provided domain list: \"$cert_file\" ~ \"$domains\"."
	else
		if [ ${#missing_domains[@]} -gt 0 ]; then
			echo "[-] Domains missing from the certificate \"$cert_file\":" >&2
			printf " \\__ %s\n" "${missing_domains[@]}" >&2
		fi
		if [ ${#extra_domains[@]} -gt 0 ]; then
			echo "[-] Domains in the certificate \"$cert_file\" not in the provided list:" >&2
			printf " \\__ %s\n" "${extra_domains[@]}"  >&2
		fi
		return 1
	fi
}

# -------------------------------------------------------
# Generate certificate authority
# ~ _selfsign_authority [--ca]
# -------------------------------------------------------
_selfsign_authority() {
	local config_ssl_dir="$1"
	local ca_expiry=""

	# check existing --ca files
	if [ -d "$config_ssl_dir" ]; then
		local ca_pem="$config_ssl_dir/certificate_authority.pem"
		if [ -f "$ca_pem" ]; then
			ca_expiry=$(_selfsign_expiry "$ca_pem" 2> /dev/null)
			if [ -n "$ca_expiry" ]; then
				local ca_key="$config_ssl_dir/certificate_authority.key"
				if [ -f "$ca_key" ]; then
					echo "[+] CA files already exist:"
					echo " \\__  -CAKey: \"$ca_key\""
					echo " \\__     -CA: \"$ca_pem\""
					echo " \\__ -Expiry: \"$ca_expiry\""
					return 0
				fi
			fi
		fi
	fi

	# generate CA
	echo "[~] Generate CA files..."
	echo " \\__ --ca: \"$config_ssl_dir\""

	# create - $config_ssl_dir if not exist
	config_ssl_dir=$(_get_existing_dir "$config_ssl_dir" "SSL CA certificate root directory option [--ca|-c] value")
	if ! [[ -n "$config_ssl_dir" && -d "$config_ssl_dir" ]]; then
		echo "[-] Failed to get or create SSL CA certificate root [--ca|-c] directory: \"$config_ssl_dir\"" >&2
		return 1
	fi

	# create - $config_ssl_dir if not exist
	if [ ! -d "$config_ssl_dir" ]; then
		echo "[*] Create directory \"$config_ssl_dir\"..."
		mkdir -p "$config_ssl_dir" > /dev/null 2>&1
		if [ ! -d "$config_ssl_dir" ]; then
			echo "[-] Failed to create directory!" >&2
			echo " \\__ \"$config_ssl_dir\"" >&2
			return 1
		fi
	fi

	# generate - certificate_authority.key
	local out_key="$config_ssl_dir/certificate_authority.key"
	if ! openssl genrsa -out "$out_key" 2048 > /dev/null 2>&1; then
		echo "[-] Generate certificate_authority.key failed!" >&2
		echo " \\__  -out \"$out_key\"" >&2
		return 1
	fi

	# generate - certificate_authority.pem
	local out_pem="$config_ssl_dir/certificate_authority.pem"
	local out_subj=$(_selfsign_subj)
	if ! openssl req -x509 -new -nodes -key "$out_key" -sha256 -days 1825 -out "$out_pem" -subj "$out_subj" > /dev/null 2>&1; then
		echo "[-] Generate certificate_authority.pem failed!" >&2
		echo " \\__  -key \"$out_key\"" >&2
		echo " \\__  -out \"$out_pem\"" >&2
		echo " \\__ -subj \"$out_subj\"" >&2
		return 1
	fi

	# success - show certificate
	ca_expiry=$(_selfsign_expiry "$out_pem" 2> /dev/null)
	echo "[+] Generate certificate authority successful."
	echo " \\__   -CAkey: \"$out_key\""
	echo " \\__      -CA: \"$out_pem\""
	echo " \\__  -Expiry: \"$ca_expiry\""
}

# -------------------------------------------------------
# Generate self-signed certificate
# ~ _selfsign_certificate [--domains] [--ssl] [--ca]
# -------------------------------------------------------
_selfsign_certificate() {
	local domain_csv="$1"
	local output_ssl_dir="$2"
	local config_ssl_dir="$3"

	# verify existing
	local ssl_verify=$(_selfsign_verify "$domain_csv" "$output_ssl_dir" "$config_ssl_dir" 2> /dev/null)
	if [ -n "$ssl_verify" ]; then
		echo "$(echo "$ssl_verify" | sed 's|Verified!|Valid self-signed certificate files already exist:|g')"
		return 0
	fi

	# generate new certificate
	echo "[~] Generate self-signed certificate files..."
	local domain="${domain_csv%%,*}" # extract the first csv item, default domain name
	if [ -z "$domain" ]; then
		echo "[-] Failed to get certificate domain."$'\n' >&2
		echo "$(_selfsign_help)"$'\n' >&2
		return 1
	fi
	output_ssl_dir="${output_ssl_dir%/}" # trim the trailing slash
	config_ssl_dir="${config_ssl_dir%/}" # trim the trailing slash
	echo " \\__ --domains: \"$domain_csv\" ~ [$domain]"
	echo " \\__     --ssl: \"$output_ssl_dir\""
	echo " \\__      --ca: \"$config_ssl_dir\""

	# create - $output_ssl_dir if not exist
	output_ssl_dir=$(_get_existing_dir "$output_ssl_dir" "SSL Certificate root directory option [--ssl|-s] value")
	if ! [[ -n "$output_ssl_dir" && -d "$output_ssl_dir" ]]; then
		echo "[-] Failed to get or create SSL Certificate root [--ssl|-s] directory: \"$output_ssl_dir\"" >&2
		return 1
	fi
	
	# generate - private.key
	local out_key="$output_ssl_dir/private.key"
	if ! openssl genrsa -out "$out_key" 2048 > /dev/null 2>&1; then
		echo "[-] Generate private.key failed:" >&2
		echo " \\__  -out: \"$out_key\"" >&2
		return 1
	fi

	# generate - request.csr
	local out_subj=$(_selfsign_subj "$domain")
	local out_csr="$output_ssl_dir/request.csr"
	# if ! openssl req -new -key "$out_key" -out "$out_csr" -subj "$out_subj" > /dev/null 2>&1; then
	if ! openssl req -new -key "$out_key" -out "$out_csr" -subj "$out_subj" > /dev/null; then
		echo "[-] Generate request.csr failed:" >&2
		echo " \\__  -key: \"$out_key\"" >&2
		echo " \\__  -out: \"$out_csr\"" >&2
		echo " \\__ -subj: \"$out_subj\"" >&2
		return 1
	fi

	# generate - config.ext
	local out_ext="$output_ssl_dir/config.ext"
	local out_ext_content=$(cat << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
EOF
)
	IFS=',' read -ra domain_array <<< "$domain_csv"
	for index in "${!domain_array[@]}"; do
		local domain_num=$((index + 1))
		local domain_name="${domain_array[$index]}"
		out_ext_content+="
DNS.$domain_num = $domain_name"
	done
	# echo "$out_ext_content" > "$out_ext" # write contents to the file, overwriting any existing content
	if ! printf "%s\n" "$out_ext_content" > "$out_ext"; then # use printf for better handling of escape sequences
		echo "[-] Generate config.ext failed:" >&2
		echo " \\__     -out: \"$out_ext\"" >&2
		echo " \\__ -content: \"$out_ext_content\"" >&2
		return 1
	fi

	# verify - certificate_authority.pem, certificate_authority.key
	local ca_pem="$config_ssl_dir/certificate_authority.pem"
	local ca_key="$config_ssl_dir/certificate_authority.key"
	if [ ! -f "$ca_pem" ] || [ ! -f "$ca_key" ]; then
		
		# generate new certificate authority files (silently)
		echo "[~] Generating missing CA files..."
		_selfsign_authority "$config_ssl_dir" > /dev/null 2>&1
		
		# re-verify
		if [ ! -f "$ca_pem" ] || [ ! -f "$ca_key" ]; then
			echo "[-] Generate CA files failed:" >&2
			echo " \\__    -CA: \"$ca_pem\"" >&2
			echo " \\__ -CAkey: \"$ca_key\"" >&2
			return 1
		else
			local ca_expiry=$(_selfsign_expiry "$ca_pem" 2> /dev/null)
			echo "[+] Generated CA files successfully."
			echo " \\__  -CAkey: \"$ca_key\""
			echo " \\__     -CA: \"$ca_pem\""
			echo " \\__ -Expiry: \"$ca_expiry\""
		fi
	fi

	# generate - certificate.pem
	local out_pem="$output_ssl_dir/certificate.pem"
	if ! openssl x509 -req -in "$out_csr" -CA "$ca_pem" -CAkey "$ca_key" -CAcreateserial -out "$out_pem" -days 825 -sha256 -extfile "$out_ext" > /dev/null 2>&1; then
		echo "[-] Generate certificate.pem failed!" >&2
		echo " \\__     -in: \"$out_csr\"" >&2
		echo " \\__     -CA: \"$ca_pem\"" >&2
		echo " \\__  -CAkey: \"$ca_key\"" >&2
		echo " \\__    -out: \"$out_pem\"" >&2
		echo " \\__ -extkey: \"$out_ext\"" >&2
		return 1
	fi

	# success - show certificate
	local out_expiry=$(_selfsign_expiry "$out_pem" 2> /dev/null)
	echo "[+] Generated self-signed certificate successfully."
	echo " \\__    -key: \"$out_key\""
	echo " \\__     -in: \"$out_csr\""
	echo " \\__ -extkey: \"$out_ext\""
	echo " \\__    -out: \"$out_pem\""
	echo " \\__ -Expiry: \"$out_expiry\""
}

# -------------------------------------------------------
# Verify self-signed certificate
# ~ _selfsign_verify [--domains] [--ssl] [--ca]
# -------------------------------------------------------
_selfsign_verify() {
	local domain_csv="$1"
	local output_ssl_dir="$2"
	local config_ssl_dir="$3"

	# check --ca files
	local ca_pem="$config_ssl_dir/certificate_authority.pem"
	if [ ! -f "$ca_pem" ]; then
		echo "[-] CA file not found: \"$ca_pem\"" >&2
		return 1
	fi
	local ca_expiry=$(_selfsign_expiry "$ca_pem" 2> /dev/null)
	if [ -z "$ca_expiry" ]; then
		echo "[-] Expired CA: \"$ca_pem\"" >&2
		return 1
	fi
	local ca_key="$config_ssl_dir/certificate_authority.key"
	if [ ! -f "$ca_key" ]; then
		echo "[-] CA file not found: \"$ca_key\"" >&2
		return 1
	fi

	# check --ssl files
	local ssl_pem="$output_ssl_dir/certificate.pem"
	if [ ! -f "$ssl_pem" ]; then
		echo "[-] SSL file not found: \"$ssl_pem\"" >&2
		return 1
	fi
	local ssl_pem_expiry=$(_selfsign_expiry "$ssl_pem" 2> /dev/null)
	if [ -z "$ssl_pem_expiry" ]; then
		echo "[-] Expired Certificate: \"$ssl_pem\"" >&2
		return 1
	fi
	local ssl_ext="$output_ssl_dir/config.ext"
	if [ ! -f "$ssl_ext" ]; then
		echo "[-] SSL file not found: \"$ssl_ext\"" >&2
		return 1
	fi
	local ssl_key="$output_ssl_dir/private.key"
	if [ ! -f "$ssl_key" ]; then
		echo "[-] SSL file not found: \"$ssl_key\"" >&2
		return 1
	fi
	local ssl_csr="$output_ssl_dir/request.csr"
	if [ ! -f "$ssl_csr" ]; then
		echo "[-] SSL file not found: \"$ssl_csr\"" >&2
		return 1
	fi
	
	# check certificate domains
	if ! _selfsign_cert_domains "$ssl_pem" "$domain_csv" > /dev/null; then
		return 1
	fi

	# verify - certificate
	if ! openssl verify -CAfile "$ca_pem" "$ssl_pem" > /dev/null 2>&1; then
		echo "[-] CA Mismatch!" >&2
		echo " └── $ca_pem (expiry: $ca_expiry)" >&2
		echo "     └── $ssl_pem (expiry: $ssl_pem_expiry)" >&2
		return 1
	fi
	echo "[+] Verified!"
	echo " └── $ca_pem (expiry: $ca_expiry)"
	echo "     └── $ssl_pem (expiry: $ssl_pem_expiry)"
}

# selfsign run mode
case $selfsign_mode in
	
	# authority [--ca|-c]
	authority)
		
		# parse --ca
		selfsign_ca=$(echo "$selfsign_ca" | xargs) # trim spaces
		if [ -n "$selfsign_ca" ]; then
			selfsign_ca=$(_get_valid_path "$selfsign_ca" "SSL CA certificate root directory option [--ca|-c] value")
		else
			selfsign_ca="$_CONFIG_SSL_CA"
		fi
		
		# _selfsign_authority [--ca]
		_selfsign_authority "$selfsign_ca"
		;;

	# certificate [--domains|-d] [--ssl|-s] [--ca|-c]
	certificate)
		
		# parse --domains
		selfsign_domain_csv=$(_get_domains_csv "$selfsign_domain_csv")
		
		# parse --ssl
		selfsign_ssl=$(echo "$selfsign_ssl" | xargs) # trim spaces
		if [ -n "$selfsign_ssl" ]; then
			selfsign_ssl=$(_get_valid_path "$selfsign_ssl" "SSL Certificate root directory option [--ssl|-s] value")
		else
			echo "[-] The SSL Certificate root directory option [--ssl|-s] value is required." >&2
			exit 1
		fi

		# parse --ca
		selfsign_ca=$(echo "$selfsign_ca" | xargs) # trim spaces
		if [ -n "$selfsign_ca" ]; then
			selfsign_ca=$(_get_valid_path "$selfsign_ca" "SSL CA certificate root directory option [--ca|-c] value")
		else
			selfsign_ca="$_CONFIG_SSL_CA"
		fi

		# _selfsign_certificate [--domains] [--ssl] [--ca]
		_selfsign_certificate "$selfsign_domain_csv" "$selfsign_ssl" "$selfsign_ca"
		;;

	# show [--file|-f]
	show)
		
		# parse --file
		selfsign_file=$(echo "$selfsign_file" | xargs) # trim spaces
		if [ -n "$selfsign_file" ]; then
			selfsign_file=$(_get_valid_path "$selfsign_file" "Certificate file path option [--file|-f] value")
		else
			echo "[1] Certificate file path option [--file|-f] value is required." >&2
			exit 1
		fi
		if [ ! -f "$selfsign_file" ]; then
			echo "[1] Certificate file does not exist: \"$selfsign_file\"." >&2
			exit 1
		fi

		# _selfsign_show [--file]
		_selfsign_show "$selfsign_file"
		;;

	# expiry [--file|-f]
	expiry)

		# parse --file
		selfsign_file=$(echo "$selfsign_file" | xargs) # trim spaces
		if [ -n "$selfsign_file" ]; then
			selfsign_file=$(_get_valid_path "$selfsign_file" "Certificate file path option [--file|-f] value")
		else
			echo "[1] Certificate file path option [--file|-f] value is required." >&2
			exit 1
		fi
		if [ ! -f "$selfsign_file" ]; then
			echo "[1] Certificate file path [--file|-f] does not exist: \"$selfsign_file\"." >&2
			exit 1
		fi

		# _selfsign_expiry [--file]
		_selfsign_expiry "$selfsign_file"
		;;

	# verify [--domains|-d] [--ssl|-s] [--ca|-c]
	verify)
		
		# parse --domains
		selfsign_domain_csv=$(_get_domains_csv "$selfsign_domain_csv")

		# parse --ssl
		selfsign_ssl=$(echo "$selfsign_ssl" | xargs) # trim spaces
		if [ -n "$selfsign_ssl" ]; then
			selfsign_ssl=$(_get_valid_path "$selfsign_ssl" "SSL Certificate root directory option [--ssl|-s] value")
		else
			echo "[-] The SSL Certificate root directory option [--ssl|-s] value is required." >&2
			exit 1
		fi
		if [ ! -d "$selfsign_ssl" ]; then
			echo "The SSL CA certificate root directory [--ssl|-s] does not exist: \"$selfsign_ssl\"." >&2
			exit 1
		fi

		# parse --ca
		selfsign_ca=$(echo "$selfsign_ca" | xargs) # trim spaces
		if [ -n "$selfsign_ca" ]; then
			selfsign_ca=$(_get_valid_path "$selfsign_ca" "SSL CA certificate root directory option [--ca|-c] value")
		else
			selfsign_ca="$_CONFIG_SSL_CA"
		fi
		if [ ! -d "$selfsign_ca" ]; then
			echo "The SSL CA certificate root directory [--ca|-c] does not exist: \"$selfsign_ca\"." >&2
			exit 1
		fi

		# _selfsign_verify [--domains] [--ssl] [--ca]
		_selfsign_verify "$selfsign_domain_csv" "$selfsign_ssl" "$selfsign_ca"
		;;
	
	# default
	*)
		echo "[-] Unsupported MODE: [$selfsign_mode]" >&2
		echo "$(_selfsign_help)" >&2
		exit 1
		;;
esac

# --- tests
# ./selfsign.sh
# 
# ./selfsign.sh authority -c www/config/ssl
#
# ./selfsign.sh certificate -d "test.com www.test.com" -s www/config/ssl/test -c www/config/ssl/ca
#
# ./selfsign.sh show -f sites.xx/config/ssl/certificate_authority.pem
# ./selfsign.sh show -f sites.xx/test/ssl/certificate.pem
#
# ./selfsign.sh expiry -f www/config/ssl/ca/certificate_authority.pem
# ./selfsign.sh expiry -f www/config/ssl/test/certificate.pem
#
# ./selfsign.sh verify -d "test.com www.test.com" -s www/config/ssl/test -c www/config/ssl/ca