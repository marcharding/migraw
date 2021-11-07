#!/usr/bin/env bash

VERSION="0.0.0.1-"$(basename "$0.tmp" | md5sum | cut -d ' ' -f 1 | cut -c1-8);

UPDATE_URL="https://raw.githubusercontent.com/marcharding/migraw/bash-win64/migraw.sh";

# colors
COLOR_NC='\e[0m'
COLOR_WHITE='\e[1;37m'
COLOR_BLACK='\e[0;30m'
COLOR_BLUE='\e[0;34m'
COLOR_GREEN='\e[0;32m'
COLOR_CYAN='\e[0;36m'
COLOR_RED='\e[0;31m'
COLOR_PURPLE='\e[0;35m'
COLOR_BROWN='\e[0;33m'
COLOR_YELLOW='\e[1;33m'

# you can get the default delegates on an *nix system with `convert -list delegate`
function create_delegates_for_im {
read -r -d "" DELEGATES <<EOL
<?xml version="1.0" encoding="UTF-8"?>
<delegatemap>
  <delegate decode="eps" encode="pdf" mode="bi" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 &quot;-sDEVICE=pdfwrite&quot; &quot;-sOutputFile=%o&quot; &quot;-f%i&quot;"/>
  <delegate decode="eps" encode="ps" mode="bi" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=ps2write&quot; &quot;-sOutputFile=%o&quot; &quot;-f%i&quot;"/>
  <delegate decode="pdf" encode="eps" mode="bi" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 -sPDFPassword=&quot;%a&quot; &quot;-sDEVICE=eps2write&quot; &quot;-sOutputFile=%o&quot; &quot;-f%i&quot;"/>
  <delegate decode="pdf" encode="ps" mode="bi" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=ps2write&quot; -sPDFPassword=&quot;%a&quot; &quot;-sOutputFile=%o&quot; &quot;-f%i&quot;"/>
  <delegate decode="ps:alpha" stealth="True" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=pngalpha&quot; -dTextAlphaBits=%u -dGraphicsAlphaBits=%u &quot;-r%s&quot; %s &quot;-sOutputFile=%s&quot; &quot;-f%s&quot; &quot;-f%s&quot;"/>
  <delegate decode="ps:cmyk" stealth="True" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=pamcmyk32&quot; -dTextAlphaBits=%u -dGraphicsAlphaBits=%u &quot;-r%s&quot; %s &quot;-sOutputFile=%s&quot; &quot;-f%s&quot; &quot;-f%s&quot;"/>
  <delegate decode="ps:color" stealth="True" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=pnmraw&quot; -dTextAlphaBits=%u -dGraphicsAlphaBits=%u &quot;-r%s&quot; %s &quot;-sOutputFile=%s&quot; &quot;-f%s&quot; &quot;-f%s&quot;"/>
  <delegate decode="ps" encode="eps" mode="bi" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=eps2write&quot; &quot;-sOutputFile=%o&quot; &quot;-f%i&quot;"/>
  <delegate decode="ps" encode="pdf" mode="bi" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=pdfwrite&quot; &quot;-sOutputFile=%o&quot; &quot;-f%i&quot;"/>
  <delegate decode="ps:mono" stealth="True" command="&quot;gswin64c.exe&quot; -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 &quot;-sDEVICE=pbmraw&quot; -dTextAlphaBits=%u -dGraphicsAlphaBits=%u &quot;-r%s&quot; %s &quot;-sOutputFile=%s&quot; &quot;-f%s&quot; &quot;-f%s&quot;"/>
</delegatemap>
EOL
echo "$DELEGATES" >> $1
}

function blackfire_config {
    mkdir -p $CONF/blackfire
read -r -d "" BLACKFIRE_SERVER <<EOL
[blackfire]
server-id=YOURSERVERID
server-token=YOURSERVERTOKEN
EOL
read -r -d "" BLACKFIRE_CLIENT <<EOL
[blackfire]
client-id=YOURCLIENTID
client-token=YOURCLIENTTOKEN
EOL
if [ ! -f "$CONF/blackfire/blackfire_agent.ini" ]; then
    echo "$BLACKFIRE_SERVER" > $CONF/blackfire/blackfire_agent.ini
fi
if [ ! -f "$CONF/blackfire/blackfire.ini" ]; then
    echo "$BLACKFIRE_CLIENT" > $CONF/blackfire/blackfire.ini
fi
}

function create_file_php_ini {
    mkdir -p `dirname "$1"`

    # if the php_ini_file option was set, use that
    if [[ "$MIGRAW_YAML_config_php_ini_file" != "" && "$MIGRAW_YAML_config_php_ini_file" != "false" ]]; then
        ln -fP $MIGRAW_YAML_config_php_ini_file $1
        return 0;
    fi

    cp -rf $BIN/php-$PHP_VERSION/php.ini-production $1

    sed -i "s|max_execution_time = 30|max_execution_time = 900|g" $1
    sed -i "s|expose_php = Off|expose_php = On|g" $1
    sed -i "s|error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT|error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED \& ~E_WARNING|g" $1
    sed -i "s|memory_limit = 128M|memory_limit = 1024M|g" $1
    sed -i "s|display_errors = Off|display_errors = On|g" $1
    sed -i "s|display_startup_errors = Off|display_startup_errors = On|g" $1
    sed -i "s|log_errors = On|log_errors = Off|g" $1
    sed -i "s|;realpath_cache_size = 4096k|realpath_cache_size = 2M|g" $1
    sed -i "s|post_max_size = 8M|post_max_size = 512M|g" $1
    sed -i "s|;opcache.max_accelerated_files=10000|opcache.max_accelerated_files=32768|g" $1

    echo "upload_max_filesize = 512M" >> $1

    mkdir -p $MIGRAW_CURRENT/php/tmp

    echo "upload_tmp_dir = $MIGRAW_CURRENT_WINDOWS\\php\\tmp" >> $1
    echo "sys_temp_dir = $MIGRAW_CURRENT_WINDOWS\\php\\tmp" >> $1
    echo "session.save_path = $MIGRAW_CURRENT_WINDOWS\\php\\session" >> $1
    echo "curl.cainfo = $BIN_WIN\\cacert.pem" >> $1
    echo "openssl.cafile = $BIN_WIN\\cacert.pem" >> $1
    echo "max_input_vars = 4096" >> $1
    echo 'date.timezone= "Europe/Berlin"' >> $1

    # configurable php ini settings
    for i in "${MIGRAW_YAML_config_php_ini[@]}"
        do :
        echo $i >> $1
    done

    PHP_EXTENSION_DIR=$BIN_WIN\\php-$PHP_VERSION\\ext

    read -r -d "" EXT <<EOL
extension_dir = $PHP_EXTENSION_DIR
extension=php_bz2.dll
extension=php_curl.dll
;extension=php_dba.dll
extension=php_enchant.dll
extension=php_exif.dll
extension=php_fileinfo.dll
$(
    if [ "$PHP_VERSION" != "5.6" ]; then
        echo "extension=php_ftp.dll"
    fi
)
$(
    if [ "$PHP_VERSION" != "8.0" ]; then
        echo "extension=php_gd2.dll"
    else
        echo "extension=php_gd.dll"
    fi
)
extension=php_gettext.dll
extension=php_gmp.dll
$(
    if [ "$PHP_VERSION" != "8.0" ]; then
        echo "extension=php_imagick.dll"
    fi
)
extension=php_imap.dll
extension=php_intl.dll
extension=php_ldap.dll
extension=php_mbstring.dll
extension=php_mysqli.dll
extension=php_openssl.dll
extension=php_pdo_mysql.dll
extension=php_pdo_pgsql.dll
extension=php_pdo_sqlite.dll
extension=php_pgsql.dll
extension=php_shmop.dll
;extension=php_snmp.dll
extension=php_soap.dll
extension=php_sockets.dll
$(
    if [ "$PHP_VERSION" != "5.6" ]; then
        echo "extension=php_sodium.dll"
    fi
)
extension=php_sqlite3.dll
extension=php_tidy.dll
$(
    if [ "$PHP_VERSION" != "8.0" ]; then
        echo "extension=php_xmlrpc.dll"
    fi
)
extension=php_xsl.dll
$(
    if [ "$PHP_VERSION" != "5.6" ] && [ "$PHP_VERSION" != "8.0" ]; then
        echo "extension=php_apcu.dll"
    fi
)
zend_extension=php_opcache.dll
$(
    if [ -f "$PHP_EXTENSION_DIR/php_blackfire.dll" ]; then
         echo "extension=php_blackfire.dll"
    fi
)
EOL

    LINE=$(grep -n 'extension_dir = "ext"' $1 | cut -d: -f 1)

    head -n $LINE $1 > $1".tmp"
    echo "$EXT" >> $1".tmp"
    tail -n $(($LINE+1)) $1 >> $1".tmp"
    mv $1".tmp" $1
}

function create_file_my_cnf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
[mysqld]
flush_time                     = 0
port                           = 3306
bind-address                   = $MIGRAW_YAML_network_ip
key_buffer_size                = 128M
max_allowed_packet             = 128M
thread_stack                   = 512K
thread_cache_size              = 16
max_connections                = 256
query_cache_limit              = 8M
query_cache_size               = 64M
sync_binlog                    = 0
# sql_mode see follwing links
# https://stackoverflow.com/a/40303542
# https://www.devside.net/wamp-server/mysql-error-incorrect-integer-value-for-column-name-at-row-1
sql_mode                       = "ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
tmp_table_size                 = 64M
innodb_buffer_pool_size        = 512M
innodb_log_file_size           = 256M
innodb_flush_log_at_trx_commit = 2
innodb_read_io_threads         = 8
innodb_write_io_threads        = 8
innodb_thread_concurrency      = 0
character-set-server           = utf8
skip-log-bin
skip-external-locking
# Due to option file escaping sequences, see https://dev.mysql.com/doc/refman/8.0/en/option-files.html we need three baskslashes
lc-messages-dir                = ${BIN_WIN//\\/\\\\}\\\mysql-5.7\\\share
lc_messages                    = en_US
sort_buffer_size               = 16777216
wait_timeout                   = 3600

[client]
default-character-set          = utf8
EOL
}

function create_file_virtual_host_conf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
<VirtualHost *:8050>
    AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$BIN_WIN/adminer"
    <Directory "$BIN_WIN/adminer">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
</VirtualHost>

<VirtualHost *:80>
	AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE_WINDOWS/$MIGRAW_YAML_document_root"
    <Directory "$MIGRAW_CURRENT_BASE_WINDOWS/$MIGRAW_YAML_document_root">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
</VirtualHost>

<VirtualHost *:443>
	AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE_WINDOWS/$MIGRAW_YAML_document_root"
    SSLEngine on
    SSLCertificateFile "$BIN_WIN\\apache-2.4\\conf\\ssl\\server.crt"
    SSLCertificateKeyFile "$BIN_WIN\\apache-2.4\\conf\\ssl\\server.key"
    <Directory "$MIGRAW_CURRENT_BASE_WINDOWS/$MIGRAW_YAML_document_root">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
</VirtualHost>
EOL
}

function create_file_httpd_conf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
# Timeout: The number of seconds before receives and sends time out.
Timeout 720

# KeepAlive: Whether or not to allow persistent connections (more than
# one request per connection). Set to "Off" to deactivate.
KeepAlive On

# MaxKeepAliveRequests: The maximum number of requests to allow
# during a persistent connection. Set to 0 to allow an unlimited amount.
MaxKeepAliveRequests 256

# KeepAliveTimeout: Number of seconds to wait for the next request from the
# same client on the same connection.
KeepAliveTimeout 4

# UseCanonicalName: Determines how Apache constructs self-referencing
# URLs and the SERVER_NAME and SERVER_PORT variables.
UseCanonicalName Off

# This directive configures what you return as the Server HTTP response
# Header.
# Set to one of:  Full | OS | Minor | Minimal | Major | Prod
ServerTokens Full

# Optionally add a line containing the server version and virtual host
# name to server-generated pages (internal error documents, FTP directory
# listings, mod_status and mod_info output etc.
ServerSignature On

# HostnameLookups: Log the names of clients or just their IP addresses
# e.g., www.apache.org (on) or 204.62.129.132 (off).
HostnameLookups Off

LogLevel error

AccessFileName .htaccess

EnableMMAP Off

<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>

# ****************************************************************************************************************
# MODULES

LoadModule access_compat_module $BIN_WIN/apache-2.4/modules/mod_access_compat.so
LoadModule actions_module $BIN_WIN/apache-2.4/modules/mod_actions.so
LoadModule alias_module $BIN_WIN/apache-2.4/modules/mod_alias.so
LoadModule allowmethods_module $BIN_WIN/apache-2.4/modules/mod_allowmethods.so
LoadModule asis_module $BIN_WIN/apache-2.4/modules/mod_asis.so
LoadModule auth_basic_module $BIN_WIN/apache-2.4/modules/mod_auth_basic.so
LoadModule authn_core_module $BIN_WIN/apache-2.4/modules/mod_authn_core.so
LoadModule authn_file_module $BIN_WIN/apache-2.4/modules/mod_authn_file.so
LoadModule authz_core_module $BIN_WIN/apache-2.4/modules/mod_authz_core.so
LoadModule authz_groupfile_module $BIN_WIN/apache-2.4/modules/mod_authz_groupfile.so
LoadModule authz_host_module $BIN_WIN/apache-2.4/modules/mod_authz_host.so
LoadModule authz_user_module $BIN_WIN/apache-2.4/modules/mod_authz_user.so
LoadModule autoindex_module $BIN_WIN/apache-2.4/modules/mod_autoindex.so
LoadModule cgi_module $BIN_WIN/apache-2.4/modules/mod_cgi.so
LoadModule dir_module $BIN_WIN/apache-2.4/modules/mod_dir.so
LoadModule env_module $BIN_WIN/apache-2.4/modules/mod_env.so
LoadModule include_module $BIN_WIN/apache-2.4/modules/mod_include.so
LoadModule mime_module $BIN_WIN/apache-2.4/modules/mod_mime.so
LoadModule negotiation_module $BIN_WIN/apache-2.4/modules/mod_negotiation.so
LoadModule rewrite_module $BIN_WIN/apache-2.4/modules/mod_rewrite.so
LoadModule setenvif_module $BIN_WIN/apache-2.4/modules/mod_setenvif.so
LoadModule vhost_alias_module $BIN_WIN/apache-2.4/modules/mod_vhost_alias.so
LoadModule headers_module $BIN_WIN/apache-2.4/modules/mod_headers.so
LoadModule ssl_module $BIN_WIN/apache-2.4/modules/mod_ssl.so

# ****************************************************************************************************************
# OTHERS CONFIG

<IfModule dir_module>
    DirectoryIndex index.html index.php index.php5 index.php6
</IfModule>

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
</IfModule>

<IfModule mime_module>
    TypesConfig conf/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
	AddType application/x-httpd-php .php
	AddType application/x-httpd-php .php5
	AddType application/x-httpd-php-source .phps
</IfModule>

<IfModule mpm_winnt_module>
    ThreadStackSize 8388608
</IfModule>

<FilesMatch ".+\.ph(ar|p|tml)$">
    SetHandler application/x-httpd-php
</FilesMatch>

<FilesMatch ".+\.phps$">
    SetHandler application/x-httpd-php-source
    # Deny access to raw php sources by default
    # To re-enable it's recommended to enable access to the files
    # only in specific virtual host or directory
    Require all denied
</FilesMatch>

# Deny access to files without filename (e.g. '.php')
<FilesMatch "^\.ph(ar|p|ps|tml)$">
    Require all denied
</FilesMatch>

Setenv MIGRAW 1
Setenv DEVELOPMENT 1

EOL
}

function migraw_init {
    if [ ! -f  $MIGRAW_CURRENT_BASE/migraw.yml ]; then
    cat > $MIGRAW_CURRENT_BASE/migraw.yml << EOL
name: migraw.default
document_root: web
network:
		ip: 127.0.0.1
		host: migraw.default.com
config:
		php: ${AVAILABLE_PHP_VERSIONS[-1]}
		php_ini_file: false
		php_ini:
			- zend_extension=php_xdebug.dll
			- xdebug.mode=debug
			- xdebug.discover_client_host = true
		apache: true
		mysql: true
		mailhog: true
exec:
	- ./init.sh
shutdown:
	- ./destroy.sh

EOL
    fi

    # see https://stackoverflow.com/questions/5750450/how-can-i-print-each-command-before-executing
    if [ ! -f  $MIGRAW_CURRENT_BASE/init.sh ]; then
    cat > $MIGRAW_CURRENT_BASE/init.sh << EOL
# set -o xtrace
trap 'echo -e "\e[0;32m" && echo -ne $(date "+%Y-%m-%d %H:%M:%S") && echo " >> Executing: $BASH_COMMAND" && echo -e "\e[0m"' DEBUG
composer install
npm install
mysql -h127.0.0.1 -uroot -e "CREATE DATABASE application"
mysql -h127.0.0.1 -uroot application < application.sql
trap - DEBUG
EOL
    fi

    if [ ! -f  $MIGRAW_CURRENT_BASE/destroy.sh ]; then
    cat > $MIGRAW_CURRENT_BASE/destroy.sh << EOL
# set -o xtrace
trap 'echo -e "\e[0;32m" && echo -ne $(date "+%Y-%m-%d %H:%M:%S") && echo " >> Executing: $BASH_COMMAND" && echo -e "\e[0m"' DEBUG
mysqldump -h127.0.0.1  --opt -uroot application -r application_$(date '+%Y%m%d_%H%M%S').sql
trap - DEBUG
EOL
    fi
}

function find_migraw_yaml {
    x=`pwd`;
    while [ "$x" != "/" ]; do
        if [ -f $x/migraw.yaml ]; then
            echo $x/migraw.yaml
            break;
        fi
        if [ -f $x/migraw.yml ]; then
            echo $x/migraw.yml
            break;
        fi
        x=`dirname "$x"`;
    done
}

# https://github.com/jasperes/bash-yaml
parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |

        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
            -e 's/\$/\\\$/g' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1], $3);
                }
            }' |

        sed -e 's/_=/+=/g' |

        awk 'BEGIN {
                FS="=";
                OFS="="
            }
            /(-|\.).*=/ {
                gsub("-|\\.", "_", $1)
            }
            { print }'
    ) < "$yaml_file"
}

function check_for_sudo {
    if [[ `uname -s` != CYGWIN* ]]; then
        if ! sudo -n true 2>/dev/null; then
            sudo -v
            echo ""
        fi
    fi
}

function install {

    echo "Installing/Downloading."

    rm -rf $DOWNLOAD
    rm -rf $BIN

    mkdir -p $DOWNLOAD
    mkdir -p $BIN

    # php
    for PHP_VERSION in ${AVAILABLE_PHP_VERSIONS[*]}
    do
        # skip/hardcodes url for non supported versions 7.0 and 5.6
        if [ "$PHP_VERSION" == "5.6" ]; then
            wget -q -O $DOWNLOAD/php-5.6.zip https://windows.php.net/downloads/releases/archives/php-5.6.40-Win32-VC11-x64.zip
            continue
        fi
        if [ "$PHP_VERSION" == "7.0" ]; then
            wget -q -O $DOWNLOAD/php-7.0.zip https://windows.php.net/downloads/releases/archives/php-7.0.33-Win32-VC14-x64.zip
            continue
        fi
        if [ "$PHP_VERSION" == "7.1" ]; then
            wget -q -O $DOWNLOAD/php-7.1.zip https://windows.php.net/downloads/releases/archives/php-7.1.33-Win32-VC14-x64.zip
            continue
        fi
        if [ "$PHP_VERSION" == "7.2" ]; then
            wget -q -O $DOWNLOAD/php-7.2.zip https://windows.php.net/downloads/releases/archives/php-7.2.34-Win32-VC15-x64.zip
            continue
        fi
        wget -q -O $DOWNLOAD/php-$PHP_VERSION.zip https://windows.php.net$(curl --silent https://windows.php.net/downloads/releases/latest/ |  grep -izoP '<a href="\K.*?php-'"$PHP_VERSION"'-Win32-V[CS][0-9][0-9]-x64[^"]+' | tr -d '\0')
    done

    # imagick
    # see https://mlocati.github.io/articles/php-windows-imagick.html
    wget -q -O $DOWNLOAD/imagick-6.9.3.zip http://windows.php.net/downloads/pecl/deps/ImageMagick-6.9.3-7-vc11-x64.zip
    wget -q -O $DOWNLOAD/imagick-7.0.7.zip http://windows.php.net/downloads/pecl/deps/ImageMagick-7.0.7-11-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-5.6.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-5.6-ts-vc11-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.0.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-7.0-ts-vc14-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.1.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.4/php_imagick-3.4.4-7.1-ts-vc14-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.2.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.4/php_imagick-3.4.4-7.2-ts-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.3.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.4/php_imagick-3.4.4-7.3-ts-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.4.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.4/php_imagick-3.4.4-7.4-ts-vc15-x64.zip

    # ghostscript
    wget -q -O $DOWNLOAD/gs950.exe https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs950/gs950w64.exe

    # mailhog
    wget -q -O $BIN/MailHog_windows_amd64.exe https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_windows_amd64.exe

    # mysql
    wget -q -O $DOWNLOAD/mysql-5.7.zip https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.31-winx64.zip

    # mariadb
    wget -q -O $DOWNLOAD/mariadb-10.3.zip https://archive.mariadb.org//mariadb-10.3.31/winx64-packages/mariadb-10.3.31-winx64.zip

    # node
    wget -q -O $DOWNLOAD/node-10.zip https://nodejs.org/dist/v10.24.1/node-v10.24.1-win-x64.zip
    wget -q -O $DOWNLOAD/node-12.zip https://nodejs.org/dist/v12.22.7/node-v12.22.7-win-x64.zip
    wget -q -O $DOWNLOAD/node-14.zip https://nodejs.org/dist/v14.18.1/node-v14.18.1-win-x64.zip
    wget -q -O $DOWNLOAD/node-16.zip https://nodejs.org/dist/v16.13.0/node-v16.13.0-win-x64.zip

    # apc
    wget -q -O $DOWNLOAD/php-apcu-5.6.zip https://windows.php.net/downloads/pecl/releases/apcu/4.0.11/php_apcu-4.0.11-5.6-ts-vc11-x64.zip
    wget -q -O $DOWNLOAD/php-apcu-7.0.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.15/php_apcu-5.1.15-7.0-ts-vc14-x64.zip
    wget -q -O $DOWNLOAD/php-apcu-7.1.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.18/php_apcu-5.1.18-7.1-ts-vc14-x64.zip
    wget -q -O $DOWNLOAD/php-apcu-7.2.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.18/php_apcu-5.1.18-7.2-ts-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-apcu-7.3.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.18/php_apcu-5.1.18-7.3-ts-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-apcu-7.4.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.18/php_apcu-5.1.18-7.4-ts-vc15-x64.zip

    # blackfire
    wget -q -O $DOWNLOAD/blackfire.zip https://packages.blackfire.io/binaries/blackfire-agent/1.48.1/blackfire-agent-windows_amd64.zip

    # blackfire modules
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-5.6.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-56.dll
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-7.0.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-70.dll
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-7.1.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-71.dll
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-7.2.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-72.dll
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-7.3.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-73.dll
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-7.4.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-74.dll
    wget -q -O $DOWNLOAD/blackfire-php-windows_x64-php-8.0.dll https://packages.blackfire.io/binaries/blackfire-php/1.48.1/blackfire-php-windows_x64-php-80.dll

    # xdebug
    wget -q -O $DOWNLOAD/php_xdebug-2.5.5-5.6-vc11-x86_64.dll https://xdebug.org/files/php_xdebug-2.5.5-5.6-vc11-x86_64.dll
    wget -q -O $DOWNLOAD/php_xdebug-2.6.1-7.0-vc14-x86_64.dll https://xdebug.org/files/php_xdebug-2.6.1-7.0-vc14-x86_64.dll
    wget -q -O $DOWNLOAD/php_xdebug-2.9.8-7.1-vc14-x86_64.dll https://xdebug.org/files/php_xdebug-2.9.8-7.1-vc14-x86_64.dll
    wget -q -O $DOWNLOAD/php_xdebug-3.0.3-7.2-vc15-x86_64.dll https://xdebug.org/files/php_xdebug-3.0.3-7.2-vc15-x86_64.dll
    wget -q -O $DOWNLOAD/php_xdebug-3.0.3-7.3-vc15-x86_64.dll https://xdebug.org/files/php_xdebug-3.0.3-7.3-vc15-x86_64.dll
    wget -q -O $DOWNLOAD/php_xdebug-3.0.3-7.4-vc15-x86_64.dll https://xdebug.org/files/php_xdebug-3.0.3-7.4-vc15-x86_64.dll
    wget -q -O $DOWNLOAD/php_xdebug-3.0.3-8.0-vs16-x86_64.dll https://xdebug.org/files/php_xdebug-3.0.3-8.0-vs16-x86_64.dll

    # ruby
    wget -q -O $DOWNLOAD/ruby-2.5.7z https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.5.7-1/rubyinstaller-2.5.7-1-x64.7z

    # winpty
    wget -q -O $DOWNLOAD/winpty.tar.gz https://github.com/rprichard/winpty/releases/download/0.4.3/winpty-0.4.3-cygwin-2.8.0-x64.tar.gz

    # adminer
    mkdir -p $BIN/adminer
    wget -q -O $BIN/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php
    wget -q -O $BIN/adminer/plugin.php https://raw.githubusercontent.com/vrana/adminer/v4.8.1/plugins/plugin.php
    wget -q -O $BIN/adminer/adminer.css https://raw.githubusercontent.com/decksterr/adminer-theme-dark/master/adminer.css
read -r -d "" DELEGATES <<EOL
<?php

error_reporting(0);
ini_set('display_errors', 0);

\$_GET["server"]  = \$_GET["server"] ?: "127.0.0.1";
\$_GET["username"] = \$_GET["username"]  ?: "root";
\$_GET["db"] = \$_GET["db"]  ?: "application";

class AdminerLoginPasswordLess {
	function login(\$login, \$password) {
		return true;
	}
	function loginForm() {
		if(!\$_GET["noautologin"]){
			echo "<script ".nonce().">setTimeout(function(){ document.querySelectorAll('[value^=Login]').item(0).click() }, 250);</script>";
		}
	}
}

function adminer_object() {
    include __DIR__ . '/plugin.php';
	return new AdminerPlugin([
		new AdminerLoginPasswordLess(),
    ]);
}

include 'adminer.php';

EOL
echo "$DELEGATES" >> $BIN/adminer/index.php

    # apache
    FILENAME=chocolatey-apache-2.4.nupkg
    curl -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" https://chocolatey.org/api/v2/package/apache-httpd -o $DOWNLOAD/$FILENAME
    unzip -uo $DOWNLOAD/$FILENAME -d $DOWNLOAD/$(basename ${FILENAME%.*})
    unzip -uo $(find $DOWNLOAD/chocolatey-apache-2.4 -name "*x64*.zip") -d $DOWNLOAD/$(basename ${FILENAME%.*})
    mv -f $DOWNLOAD/chocolatey-apache-2.4/Apache24 $BIN/apache-2.4

    # cacert
    wget -q -O $BIN/cacert.pem https://curl.haxx.se/ca/cacert.pem

    # composer
    mkdir -p $BIN/composer/
    wget -q -O $BIN/composer/composer-1.phar https://getcomposer.org/composer-1.phar
    wget -q -O $BIN/composer/composer-2.phar https://getcomposer.org/composer-2.phar
    cp $BIN/composer/composer-2.phar $BIN/composer/composer.phar

    # extract files
    echo "Extracting:"

    for FILENAME in $DOWNLOAD/*.zip
    do
        echo "Extracting" $FILENAME
        unzip -uo $FILENAME -d $BIN/$(basename ${FILENAME%.*})
    done

    # mysql cleanup
    mv $BIN/mysql-5.7/mysql-5.7.31-winx64/* $BIN/mysql-5.7
    rm -rf $BIN/mysql-5.7/mysql-5.7.31-winx64

    # mariadb cleanup
    mv $BIN/mariadb-10.3/mariadb-10.3.27-winx64/* $BIN/mariadb-10.3
    rm -rf $BIN/mariadb-10.3/mariadb-10.3.27-winx64

    # mysql
    ln -rsf $BIN/mysql-5.7/bin/mysql.exe $BIN/mysql-5.7/bin/mysql
    chmod +x $BIN/mysql-5.7/bin/mysql

    # mariadb
    ln -rsf $BIN/mariadb-10.3/bin/mysql.exe $BIN/mariadb-10.3/bin/mysql
    chmod +x $BIN/mariadb-10.3/bin/mysql

    # check if mysql alias is working, if not, use the bat/shell script wrapper method
    if ($BIN/mysql-5.7/bin/mysql -v 2>&1 | grep -q "Invalid argument")
    then
        rm -rf $BIN/mysql-5.7/bin/mysql
        echo $($PATH_CONVERT_BIN -w $BIN/mysql-5.7/bin/mysql.exe)' "%*" ' > $BIN/mysql-5.7/bin/mysql.bat
        echo "$PATH_CMD /c"' "'$($PATH_CONVERT_BIN -w $BIN/mysql-5.7/bin/mysql.bat)' "''"$@"' > $BIN/mysql-5.7/bin/mysql
        chmod +x $BIN/mysql-5.7/bin/mysql.bat
        chmod +x $BIN/mysql-5.7/bin/mysql
    fi

    # check if mysql alias is working, if not, use the bat/shell script wrapper method
    if ($BIN/mariadb-10.3/bin/mysql -v 2>&1 | grep -q "Invalid argument")
    then
        rm -rf $BIN/mariadb-10.3/bin/mysql
        echo $($PATH_CONVERT_BIN -w $BIN/mariadb-10.3/bin/mysql.exe)' "%*" ' > $BIN/mariadb-10.3/bin/mysql.bat
        echo "$PATH_CMD /c"' "'$($PATH_CONVERT_BIN -w $BIN/mariadb-10.3/bin/mysql.bat)' "''"$@"' > $BIN/mariadb-10.3/bin/mysql
        chmod +x $BIN/mariadb-10.3/bin/mysql.bat
        chmod +x $BIN/mariadb-10.3/bin/mysql
    fi

    # node 10 cleanup
    mv $BIN/node-10/node-v10.24.0-win-x64/* $BIN/node-10
    rm -rf $BIN/node-10/node-v10.24.0-win-x64
    ln -rsf $BIN/node-10/node.exe $BIN/node-10/node
    chmod +x $BIN/node-10/node

    # node 12 cleanup
    mv $BIN/node-12/node-v12.21.0-win-x64/* $BIN/node-12
    rm -rf $BIN/node-12/node-v12.21.0-win-x64
    ln -rsf $BIN/node-12/node.exe $BIN/node-12/node
    chmod +x $BIN/node-12/node

    # node 14 cleanup
    mv $BIN/node-14/node-v14.16.0-win-x64/* $BIN/node-14
    rm -rf $BIN/node-14/node-v14.16.0-win-x64
    ln -rsf $BIN/node-14/node.exe $BIN/node-14/node
    chmod +x $BIN/node-14/node

    # extract ruby
    for FILENAME in $DOWNLOAD/*.7z
    do
        echo "Extracting" $FILENAME
        7zr x $FILENAME -o$DOWNLOAD
    done
    mv $DOWNLOAD/rubyinstaller-2.5.7-1-x64 $BIN/ruby-2.5

    # fix ruby symlink
    ln -rsf $BIN/ruby-2.5//bin/ruby.exe $BIN/ruby-2.5//bin/ruby
    chmod +x $BIN/ruby-2.5//bin/ruby

    # extract ghostscript
    7z -aoa x $DOWNLOAD/gs950.exe -o$BIN/gs950

    # extract winpty
    mkdir -o $BIN/winpty
    tar -zxf $DOWNLOAD/winpty.tar.gz --directory $BIN/winpty
    cp -rf $BIN/winpty/winpty-0.4.3-cygwin-2.8.0-x64/bin/* $BIN/winpty

    # add custom delegate to make pdf conversion work, see https://stackoverflow.com/a/32163666
    create_delegates_for_im $BIN/imagick-6.9.3/bin/delegates.xml
    create_delegates_for_im $BIN/imagick-7.0.7/bin/delegates.xml

    # copy imagemagik, apc and blackfire dlls
    for PHP_VERSION in ${AVAILABLE_PHP_VERSIONS[*]}
    do
        cp -rf $(find $BIN/php-imagick-$PHP_VERSION -name "php_*.dll") $BIN/php-$PHP_VERSION/ext
        cp -rf $(find $BIN/php-apcu-$PHP_VERSION -name "php_*.dll") $BIN/php-$PHP_VERSION/ext
        cp -rf $DOWNLOAD/php_xdebug-*-$PHP_VERSION-vc*-x86_64.dll $BIN/php-$PHP_VERSION/ext/php_xdebug.dll
        cp -rf $DOWNLOAD/blackfire-php-windows_x64-php-$PHP_VERSION.dll $BIN/php-$PHP_VERSION/ext/php_blackfire.dll
    done

    unset PHP_VERSION

    # install often used libaries
    echo -e "\n${COLOR_CYAN}Executing:${COLOR_NC} npm install -g yarn\n"
    spawn_bash "npm install -g yarn"
    echo -e "\n${COLOR_CYAN}Executing:${COLOR_NC} gem install capistrano\n"
    spawn_bash "gem install capistrano"

    # init blackfire config files
    mkdir -p $BIN/blackfire/links
    echo "@echo off" > $BIN/blackfire/links/blackfire.bat
    echo $($PATH_CONVERT_BIN -w $BIN/blackfire/blackfire.exe)' --config='$($PATH_CONVERT_BIN -w $CONF/blackfire/blackfire.ini)' %* ' >> $BIN/blackfire/links/blackfire.bat
    echo "@echo off" > $BIN/blackfire/links/blackfire-agent.bat
    echo $($PATH_CONVERT_BIN -w $BIN/blackfire/blackfire-agent.exe)' --config='$($PATH_CONVERT_BIN -w $CONF/blackfire/blackfire_agent.ini)' %* ' >> $BIN/blackfire/links/blackfire-agent.bat
    chmod +x $BIN/blackfire/links/blackfire-agent.bat
    chmod +x $BIN/blackfire/links/blackfire.bat
    ln -rsf $BIN/blackfire/links/blackfire-agent.bat $BIN/blackfire/links/blackfire-agent
    ln -rsf $BIN/blackfire/links/blackfire.bat $BIN/blackfire/links/blackfire
    blackfire_config

    # set owner for binaries, cygwin/wsl somehow messes this up sometimes
    # https://superuser.com/a/813881
    takeown /F $BIN_WIN /R /D Y > /dev/null
    icacls $BIN_WIN /T /Q /C /RESET > /dev/null
}

function set_path {
    PATH=$WINDOWS_BASE_PATH
    PATH=$BIN/apache-2.4/bin:$PATH
    PATH=$BIN/php-$PHP_VERSION:$PATH
    PATH=$BIN/composer:$PATH
    PATH=$BIN/node-$NODE_VERSION:$PATH
    PATH=$BIN/ruby-2.5/bin:$PATH

    if [ "$MIGRAW_YAML_config_mysql" == "true" ]; then
        PATH=$BIN/mysql-5.7/bin:$PATH
    fi

    if [ "$MIGRAW_YAML_config_mariadb" == "true" ]; then
        PATH=$BIN/mariadb-10.3/bin:$PATH
    fi

    PATH=$BIN/gs950/bin:$PATH
    PATH=$BIN/gs950/lib:$PATH
    PATH=$BIN/blackfire/links:$PATH

    if [[ "$PHP_VERSION" == "5.6" || "$PHP_VERSION" == "7.0" || "$PHP_VERSION" == "7.1" ]]; then
        PATH=$BIN/imagick-6.9.3/bin:$PATH
    fi

    if [[ "$PHP_VERSION" == "7.2" || "$PHP_VERSION" == "7.3" || "$PHP_VERSION" == "7.4" ]]; then
        PATH=$BIN/imagick-7.0.7/bin:$PATH
    fi

    PATH=$MIGRAW_CURRENT_BASE/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/vendor/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/node_modules/.bin:$PATH

    PATH=$MIGRAW_CURRENT/gem/bin:$PATH
    PATH=$MIGRAW_CURRENT/bin:$PATH

    SystemDrive=C:

    PHP_INI_SCAN_DIR=$MIGRAW_CURRENT
    PHPRC=$MIGRAW_CURRENT/php
    MYSQL_HOME=$MIGRAW_CURRENT/mysql
    OPENSSL_CONF=$BIN/apache-2.4/conf/openssl.cnf

    WSLENV=PATH/l:PHP_INI_SCAN_DIR/p:PHPRC/p:MYSQL_HOME/p:OPENSSL_CONF/p

    # prepend system32 last, sometime it caused problems being at the start of $PATH, append linux prefixes because the prefer our own binaries
    PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$WINDOWS_BASE_PATH"/system32"

    mkdir -p $HOME/.composer
    COMPOSER_HOME=$HOME/.composer

    mkdir -p $MIGRAW_CURRENT/php/session
    create_file_php_ini $MIGRAW_CURRENT/php/php.ini

    if [[ `uname -s` == CYGWIN* ]]; then
        PHPRC=$($PATH_CONVERT_BIN -w $PHPRC)
        PHP_INI_SCAN_DIR=$($PATH_CONVERT_BIN -w $PHP_INI_SCAN_DIR)
        MYSQL_HOME=$($PATH_CONVERT_BIN -w $MYSQL_HOME)
        COMPOSER_HOME=$($PATH_CONVERT_BIN -w $COMPOSER_HOME)
        OPENSSL_CONF=$($PATH_CONVERT_BIN -w $OPENSSL_CONF)
    fi

    export PATH
    export COMPOSER_HOME
    export WSLENV
    export PHPRC
    export PHP_INI_SCAN_DIR
    export MYSQL_HOME
    export OPENSSL_CONF
    export SystemDrive
}

function start {
    set_path
    mysql_start init
    apache_start
    mailhog_start
}

function unpause {
    set_path
    mysql_start
    apache_start
    mailhog_start
}

function clean {
    rm -rf $MIGRAW_CURRENT
}

function stats {
    # https://stackoverflow.com/questions/3043978/how-to-check-if-a-process-id-pid-exists
    # https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tasklist
    $MIGRAW_CURRENT/mysql/.pid
    $MIGRAW_CURRENT/httpd/httpd.pid
}

function copy_file_if_target_not_exists {
    if [ ! -f $2 ]; then
        cp -f $1 $1
    fi
}

function stop {
    if [ -f $MIGRAW_CURRENT/mysql/mysql.pid ]; then
        PID=`cat "$MIGRAW_CURRENT/mysql/mysql.pid" | tr -dc '0-9'`
        $PATH_CMD /c "taskkill.exe /F /PID $PID > nul" > /dev/null 2>&1

        counter=1
        while $BIN_MYSQL -h127.0.0.1 -uroot -e "show databases;" > /dev/null 2>&1; do
            sleep 1
            counter=`expr $counter + 1`
            if [ $counter -gt 30 ]; then
                echo "We have been waiting for MySQL too long already; failing."
                exit 1
            fi
        done

        rm -rf $MIGRAW_CURRENT/mysql/mysql.pid
    fi

    if [ -f $MIGRAW_CURRENT/httpd/httpd.pid ]; then
        PID=`cat $MIGRAW_CURRENT/httpd/httpd.pid | tr -dc '0-9'`
        $PATH_CMD /c "taskkill.exe /F /PID $PID > nul" > /dev/null 2>&1
        rm -rf $MIGRAW_CURRENT/httpd/httpd.pid
    fi

    if [ -f $MIGRAW_CURRENT/mailhog/mailhog.pid ]; then
        PID=`cat $MIGRAW_CURRENT/mailhog/mailhog.pid | tr -dc '0-9'`
        $PATH_CMD /c "taskkill.exe /F /PID $PID > nul" > /dev/null 2>&1
        rm -rf $MIGRAW_CURRENT/mailhog/mailhog.pid
    fi
}

function prepare_shell {

    read -r -d "" PHP <<EOL
        ARGS=""
        CMD_UUID=\$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

        for arg in "\$@"
        do
            if [[ -d \$arg || -f \$arg ]]; then
                ARGS=\$ARGS" "\$($PATH_CONVERT_BIN -w \$arg)
            else
                if [[ \$arg == "-"* ]]; then
                    ARGS=\$ARGS" "\$arg
                else
                    ARGS=\$ARGS" "'"'\$arg'"'
                fi
            fi
        done

        CMD_FILE="$MIGRAW_CURRENT""/php/"\$CMD_UUID.bat
        CMD_FILE_WINDOWS=\$($PATH_CONVERT_BIN -w "\$CMD_FILE")
        echo "@echo off" > \$CMD_FILE
        echo "$BIN_WIN\php-$PHP_VERSION\php.exe"' -c "$MIGRAW_CURRENT_WINDOWS\\php\\php.ini" -d "memory_limit=-1" ' \$ARGS >> \$CMD_FILE
        echo "EXIT 0" >> \$CMD_FILE
        # create path enviroment

        PATH=$MIGRAW_CURRENT/bin:$BIN/apache-2.4/bin:$BIN/php-$PHP_VERSION:$BIN/mysql-5.7/bin:$WINDOWS_BASE_PATH:/usr/bin:$WINDOWS_BASE_PATH/system32

        if [[ "$PHP_VERSION" == "5.6" || "$PHP_VERSION" == "7.0" || "$PHP_VERSION" == "7.1" ]]; then
            PATH=\$PATH:$BIN/imagick-6.9.3/bin
        fi

        if [[ "$PHP_VERSION" == "7.2" || "$PHP_VERSION" == "7.3" || "$PHP_VERSION" == "7.4" ]]; then
            PATH=\$PATH:$BIN/imagick-7.0.7/bin
        fi

        WSLENV=PATH/l:PHP_INI_SCAN_DIR/p

        $PATH_CMD /c \$CMD_FILE_WINDOWS
        /bin/rm -rf \$CMD_FILE
EOL

    read -r -d '' PHP_BAT <<EOL
        @echo off
        $BIN_WIN\php-$PHP_VERSION\php.exe -c "$PHPRC\\php.ini" -d "memory_limit=-1" %*
        EXIT 0
EOL

    read -r -d '' COMPOSER <<EOL
        php $BIN/composer/composer.phar "\$@"
EOL

    read -r -d '' COMPOSER_BAT <<EOL
        @echo off
        php $BIN_WIN/composer/composer.phar  %*
        EXIT 0
EOL

    read -r -d '' COMPOSER2 <<EOL
        php $BIN/composer/composer-2.phar "\$@"
EOL

    read -r -d '' COMPOSER2_BAT <<EOL
        @echo off
        php $BIN_WIN/composer/composer-2.phar  %*
        EXIT 0
EOL

    read -r -d '' NPM_BAT <<EOL
        $PATH_CMD /c "$BIN_WIN\node-$NODE_VERSION\npm.cmd" "\$@"
EOL

    read -r -d '' GRUNT_BAT <<EOL
        $PATH_CMD /c "$BIN_WIN\node-$NODE_VERSION\grunt.cmd" "\$@"
EOL

    read -r -d '' GEM_BAT <<EOL
        $PATH_CMD /c "$BIN_WIN\ruby-2.5\bin\gem.cmd" "\$@"
EOL

    read -r -d '' BUNDLER_BAT <<EOL
        $PATH_CMD /c "$BIN_WIN\ruby-2.5\bin\bundler.bat" "\$@"
EOL

    read -r -d '' CAP_BAT <<EOL
        $PATH_CMD /c "$BIN_WIN\ruby-2.5\bin\cap.bat" "\$@"
EOL

    mkdir -p $MIGRAW_CURRENT/bin

    # solve this as a loop?
    echo "$PHP" > $MIGRAW_CURRENT/bin/php && chmod +x $MIGRAW_CURRENT/bin/php
    echo "$PHP_BAT" > $MIGRAW_CURRENT/bin/php.bat && chmod +x $MIGRAW_CURRENT/bin/php.bat
    echo "$COMPOSER" > $MIGRAW_CURRENT/bin/composer && chmod +x $MIGRAW_CURRENT/bin/composer
    echo "$COMPOSER_BAT" > $MIGRAW_CURRENT/bin/composer.bat && chmod +x $MIGRAW_CURRENT/bin/composer.bat
    echo "$COMPOSER2" > $MIGRAW_CURRENT/bin/composer2 && chmod +x $MIGRAW_CURRENT/bin/composer2
    echo "$COMPOSER2_BAT" > $MIGRAW_CURRENT/bin/composer2.bat && chmod +x $MIGRAW_CURRENT/bin/composer2.bat
    echo "$NPM_BAT" > $MIGRAW_CURRENT/bin/npm && chmod +x $MIGRAW_CURRENT/bin/npm
    echo "$GRUNT_BAT" > $MIGRAW_CURRENT/bin/grunt && chmod +x $MIGRAW_CURRENT/bin/grunt
    echo "$GEM_BAT" > $MIGRAW_CURRENT/bin/gem && chmod +x $MIGRAW_CURRENT/bin/gem
    echo "$BUNDLER_BAT" > $MIGRAW_CURRENT/bin/bundler && chmod +x $MIGRAW_CURRENT/bin/bundler
    echo "$CAP_BAT" > $MIGRAW_CURRENT/bin/cap && chmod +x $MIGRAW_CURRENT/bin/cap

}

function spawn_shell {
    set_path

    prepare_shell

    if [ -n "$ZSH_NAME" ]; then
        spawn_zsh $1
    elif [ -n "$BASH_VERSION" ]; then
        spawn_bash $1
    else
        # Error
        echo "No suitable shell found."
    fi

}

function spawn_bash {
    prepare_shell

    PROMPT="\n${COLOR_PURPLE}\t ${MIGRAW_USER}@${MIGRAW_YAML_name}${COLOR_NC} [${COLOR_RED}\w${COLOR_NC}]${COLOR_NC}\n€${COLOR_NC} "

    if [ "$1" != "" ]; then
        env -i WSLENV=$WSLENV PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH COMPOSER_HOME=$COMPOSER_HOME SystemDrive=$SystemDrive CYGWIN=$CYGWIN OPENSSL_CONF=$OPENSSL_CONF HOME=$HOME bash -c "$1"
    else
        env -i WSLENV=$WSLENV PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH COMPOSER_HOME=$COMPOSER_HOME SystemDrive=$SystemDrive CYGWIN=$CYGWIN OPENSSL_CONF=$OPENSSL_CONF HOME=$HOME bash --rcfile <(echo ' PS1="'$(echo $PROMPT)' "')
    fi
}

function spawn_zsh {
    prepare_shell

    if [ "$1" != "" ]; then
        env -i WSLENV=$WSLENV PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH COMPOSER_HOME=$COMPOSER_HOME SystemDrive=$SystemDrive CYGWIN=$CYGWIN HOME=$HOME zsh -c "$1"
    else
        mkdir -p $MIGRAW_CURRENT/shell
        cp -f ~/.zshrc $MIGRAW_CURRENT/shell/.zshrc
        read -r -d "" ZSHRC <<EOL
    function prompt_migraw_env() {
        p10k segment -f 208 -i '' -t '${MIGRAW_YAML_name}'
    };
POWERLEVEL9K_DIR_FOREGROUND=208
POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=208
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=("\${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[@]}" "migraw_env")
EOL
        echo "" >> $MIGRAW_CURRENT/shell/.zshrc
        echo "$ZSHRC" >> $MIGRAW_CURRENT/shell/.zshrc
        env -i ZDOTDIR=$MIGRAW_CURRENT/shell WSLENV=$WSLENV PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH COMPOSER_HOME=$COMPOSER_HOME SystemDrive=$SystemDrive CYGWIN=$CYGWIN HOME=$HOME zsh
    fi
}

function mailhog_start {
    if [ "$MIGRAW_YAML_config_mailhog" != "true" ]; then
        return
    fi
    mkdir -p $MIGRAW_CURRENT/mailhog/log
    chmod +x $BIN/MailHog_windows_amd64.exe
    $BIN/MailHog_windows_amd64.exe > $MIGRAW_CURRENT/mailhog/log/mailhog.log 2>&1 & echo "$!" > $MIGRAW_CURRENT/mailhog/mailhog.pid
}

function mysql_start {

    DATABASE=""

    if [ "$MIGRAW_YAML_config_mysql" == "true" ]; then
        DATABASE="mysql-5.7"
    fi

    if [ "$MIGRAW_YAML_config_mariadb" == "true" ]; then
        DATABASE="mariadb-10.3"
    fi

    if [ -z "${DATABASE}" ]; then
        return
    fi

    BIN_MYSQLD="$BIN/$DATABASE/bin/mysqld.exe"
    BIN_MYSQL_INSTALLDB="$BIN/$DATABASE/bin/mysql_install_db.exe"
    BIN_MYSQL="$BIN/$DATABASE/bin/mysql.exe"

    chmod +x $BIN_MYSQLD
    chmod +x $BIN_MYSQL

    MYSQL_BASE_PATH=$MIGRAW_CURRENT/mysql
    MYSQL_BASE_PATH_WINDOWS=$MIGRAW_CURRENT_WINDOWS\\mysql

    if [ "$1" == "init" ]; then
        rm -rf $MYSQL_BASE_PATH
        mkdir -p $MYSQL_BASE_PATH/data $MYSQL_BASE_PATH/secure $MYSQL_BASE_PATH/tmp $MYSQL_BASE_PATH/log
        create_file_my_cnf $MYSQL_BASE_PATH/my.cnf

        if [ "$MIGRAW_YAML_config_mysql" == "true" ]; then
            $BIN_MYSQLD --initialize-insecure --basedir="$MYSQL_BASE_PATH_WINDOWS" --datadir=$MYSQL_BASE_PATH_WINDOWS\\data
        fi

        if [ "$MIGRAW_YAML_config_mariadb" == "true" ]; then
            $BIN_MYSQL_INSTALLDB --datadir=$MYSQL_BASE_PATH_WINDOWS\\data
        fi
    fi

    read -r -d "" BIN_MYSQL_CMD <<EOL
        @echo off
        start /B $($PATH_CONVERT_BIN -w $BIN_MYSQLD) \
        --defaults-file="$MYSQL_BASE_PATH_WINDOWS\\my.cnf" \
        --log_error="$MYSQL_BASE_PATH_WINDOWS\\log\\log.err" \
        --pid_file="$MYSQL_BASE_PATH_WINDOWS\\mysql.pid" \
        --basedir="$MYSQL_BASE_PATH_WINDOWS" \
        --tmpdir="$MYSQL_BASE_PATH_WINDOWS\\tmp" \
        --datadir="$MYSQL_BASE_PATH_WINDOWS\\data" &
EOL

    echo "$BIN_MYSQL_CMD" | tr -s ' ' > $MIGRAW_CURRENT/mysql/exec.bat
    cygstart --hide $PATH_CMD /c $($PATH_CONVERT_BIN -w $MIGRAW_CURRENT/mysql/exec.bat)

    counter=1
    while ! $BIN_MYSQL -h127.0.0.1 -uroot -e "show databases;" > /dev/null 2>&1; do
        sleep 1
        counter=`expr $counter + 1`
        if [ $counter -gt 30 ]; then
            echo "We have been waiting for MySQL too long already; failing."
            exit 1
        fi
    done

}

function apache_start {

    if [ "$MIGRAW_YAML_config_apache" != "true" ]; then
        return
    fi

    BIN_HTTPD="$BIN/apache-2.4/bin/httpd.exe"
    chmod +x $BIN_HTTPD

    mkdir -p $MIGRAW_CURRENT/httpd $MIGRAW_CURRENT/httpd/log $MIGRAW_CURRENT/httpd/sites

    create_file_httpd_conf $MIGRAW_CURRENT/httpd/httpd.conf
    create_file_virtual_host_conf $MIGRAW_CURRENT/httpd/sites/default.conf

    read -r -d "" BIN_HTTPD_CMD <<EOL
        @echo off
        start /B $($PATH_CONVERT_BIN -w $BIN_HTTPD) \
        -f "$MIGRAW_CURRENT_WINDOWS\\httpd\\httpd.conf" \
        -DDEVELOPMENT \
        -DMIGRAW \
        -c "PidFile $MIGRAW_CURRENT_WINDOWS\\httpd\\httpd.pid" \
        -c "ServerRoot $BIN_WIN\\apache-2.4" \
        -c "ServerName $MIGRAW_YAML_name" \
        -c "ServerAdmin admin@$MIGRAW_YAML_name" \
        -c "Listen $MIGRAW_YAML_network_ip:80" \
        -c "Listen $MIGRAW_YAML_network_ip:443" \
        -c "Listen $MIGRAW_YAML_network_ip:8050" \
        -c "Include $MIGRAW_CURRENT_WINDOWS\\httpd\\sites\\*.conf" \
        -c "ErrorLog $MIGRAW_CURRENT_WINDOWS\\httpd\\log\\error.log" \
        $(
            for DLL_PATH in $BIN/php-$PHP_VERSION/*.dll
            do
                DLL_FILENAME="$(basename $DLL_PATH)"
                if  [[ $DLL_FILENAME == php* || $DLL_FILENAME == 'libeay32.dll' || $DLL_FILENAME == 'ssleay32.dll' || $DLL_FILENAME == 'libssl-1_1-x64.dll' ]];
                then
                    continue;
                fi
                DLL_WINDOWS_PATH="$($PATH_CONVERT_BIN -w $DLL_PATH)"
                printf %s " -c \"LoadFile $DLL_WINDOWS_PATH\""
            done
        ) \
        $(
            if  [[ ${PHP_VERSION:0:1} == 8 ]];
            then
                echo " -c \"LoadModule php_module $BIN_WIN\\php-$PHP_VERSION\\php${PHP_VERSION:0:1}apache2_4.dll\""
            else
                echo " -c \"LoadModule php${PHP_VERSION:0:1}_module $BIN_WIN\\php-$PHP_VERSION\\php${PHP_VERSION:0:1}apache2_4.dll\""
            fi
        ) \
        -c "PHPIniDir $MIGRAW_CURRENT_WINDOWS\\php" &
EOL

# somehow executing it as a bat script with cmd.exe is the only way to ensure everything works most of the time
# executing directly via interop (when using wsl 1) results in ddls not loaded sometimes (more often as when using this approach)
echo "$BIN_HTTPD_CMD" | tr -s ' ' > $MIGRAW_CURRENT/httpd/exec.bat
cygstart --hide $PATH_CMD /c $($PATH_CONVERT_BIN -w $MIGRAW_CURRENT/httpd/exec.bat)

}

# see https://stackoverflow.com/a/38275644
function execute_with_progress_spinner {
    if [ "$OPTION" == "debug" ]; then
        $1
    else
        echo -ne "${COLOR_BROWN}Working ${COLOR_NC}"
        (while :; do for c in / - \\ \|; do printf "${COLOR_BROWN}[%s]${COLOR_NC}" "$c"; sleep 0.1; printf '\b\b\b'; done; done) &
        touch $BASE/migraw.log
        SPINNER=$!
        {
            $1 > $BASE/migraw.log 2>&1
        }
        {
            echo -e "${COLOR_NC}\r${COLOR_PURPLE}Finished.         ${COLOR_NC}";
            kill $SPINNER && wait $SPINNER;
        } 2>/dev/null
    fi
}

# adapted from https://stackoverflow.com/q/8595751
function self_update {
    FILE=$(readlink -f "$0")

    if ! wget --quiet --output-document="$0.tmp" $UPDATE_URL ; then
        echo -e "${COLOR_PURPLE}Error while trying to download the update.${COLOR_NC}\n"
        exit 1
    fi

    CURRENT_VERSION_MD5=$(basename "$FILE" | md5sum | cut -d ' ' -f 1)
    NEW_VERSION_MD5=$(basename "$0.tmp" | md5sum | cut -d ' ' -f 1)
    if [ $CURRENT_VERSION_MD5 == $NEW_VERSION_MD5 ]; then
        echo -e "${COLOR_PURPLE}No update found, you already have the latest version.${COLOR_NC}\n"
        exit 1
    fi

    # Copy over modes from old version
    OCTAL_MODE=$(stat -c '%a' $0)
    if ! chmod $OCTAL_MODE "$0.tmp" ; then
        echo -e "${COLOR_PURPLE}Error while trying to set mode on update file.${COLOR_NC}\n"
        exit 1
    fi

    if mv "$0.tmp" "$FILE"; then
        echo -e "${COLOR_CYAN}Update complete.${COLOR_NC}\n"
    else
        echo -e "${COLOR_PURPLE}Update failed while moving update file.${COLOR_NC}\n"
    fi
}

function usage {

cat <<EOF

$(echo -e "${COLOR_CYAN}migraw wsl|cygwin/win64 $VERSION${COLOR_NC}")

Usage:
  $(echo -e "${COLOR_CYAN}migraw${COLOR_NC}") [$(echo -e "${COLOR_GREEN}command${COLOR_NC}")] [$(echo -e "${COLOR_PURPLE}options${COLOR_NC}")]

Options:
  $(echo -e "${COLOR_PURPLE}--debug ${COLOR_NC}")            Show debug information

Commands:
  $(echo -e "${COLOR_GREEN}up|start${COLOR_NC}")            Start migraw instance.
  $(echo -e "${COLOR_GREEN}suspend|pause${COLOR_NC}")       Suspend migraw instance (data stays).
  $(echo -e "${COLOR_GREEN}resume|unpause${COLOR_NC}")      Resume migraw instance.
  $(echo -e "${COLOR_GREEN}bash${COLOR_NC}")                Spwans a bash within the current migraw enviroment.
  $(echo -e "${COLOR_GREEN}bash [cmd]${COLOR_NC}")          Runs [cmd] within the current migraw enviroment.
  $(echo -e "${COLOR_GREEN}install${COLOR_NC}")             Install all binaries, can also be used to update.
  $(echo -e "${COLOR_GREEN}selfupdate${COLOR_NC}")          Update migraw
  $(echo -e "${COLOR_GREEN}init${COLOR_NC}")                Update create demo migraw.yml, init.sh and destroy.sh
  $(echo -e "${COLOR_GREEN}info${COLOR_NC}")                Display info and help
EOF

}

function info {

cat <<EOF

$(echo -e "${COLOR_CYAN}Help and info for running migraw.${COLOR_NC}")

The following settings are recommended:

Native symlinks in cygwin:
  Add the follwing line to your .bashrc:
  export CYGWIN="winsymlinks:native"
  See http://cygwin.com/cygwin-ug-net/using.html#pathnames-symlinks for further infos

Recommended firewall exclusions (ps command):
  \$processes = @("mysqld.exe", "mysql.exe", "php.exe", "httpd.exe", "ruby.exe", "node.exe", "git.exe")
  \$processes | ForEach { Add-MpPreference -ExclusionProcess (\$_) }
EOF

}

function is_admin
{
    net session > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "\n${COLOR_RED}!!! Migraw is not run with elevated privileges, symlinks may not work !!!${COLOR_NC}";
    fi
}

function update_hosts
{
    net session > /dev/null 2>&1
    if [ $? == 0 ]; then
        if [ "$MIGRAW_YAML_network_host" != "" ]; then
            HOSTS=$WINDIR/System32/drivers/etc/hosts
            if ! grep -q "$MIGRAW_YAML_network_host" $HOSTS; then
                echo "127.0.0.1 $MIGRAW_YAML_network_host" >> $HOSTS
            fi
        fi
    fi
}

function are_you_sure
{
    echo ""
    read -p "y/n: " REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
}

is_admin

ACTION=$1

OPTION="${2//-}"

# base dir
BASE="$( cd "$(dirname "$0")" ; pwd -P )"

# .migraw base
MIGRAW_BASE=$BASE/.migraw

# migraw user
if [ "$SUDO_USER" != "" ]; then
    MIGRAW_USER=$SUDO_USER
else
    MIGRAW_USER=$USER
fi

# script origin base dir
SCRIPT_BASE="$(dirname "$(readlink -f "$0")")"/data

# download dir
DOWNLOAD=$SCRIPT_BASE/download

# bin base
BIN=$SCRIPT_BASE/bin

# determine cmd.exe path and path convert binary
if [[ `uname -s` == CYGWIN* ]]; then
    PATH_CONVERT_BIN="/usr/bin/cygpath"
    PATH_CMD="cmd.exe"
else
    PATH_CONVERT_BIN="/bin/wslpath"
    PATH_CMD="cmd.exe"
fi

WINDOWS_BASE_PATH_WIN=$(cmd.exe /c "echo %windir%")
WINDOWS_BASE_PATH_WIN=$(tr -dc '[[:print:]]' <<< "$WINDOWS_BASE_PATH_WIN")
WINDOWS_BASE_PATH=$($PATH_CONVERT_BIN -u $WINDOWS_BASE_PATH_WIN)

# download dir windows
DOWNLOAD_WIN=$($PATH_CONVERT_BIN -w $DOWNLOAD)

# bin base windows
BIN_WIN=$($PATH_CONVERT_BIN -w $BIN)

# additional config base
CONF=$SCRIPT_BASE/conf
CONF_WIN=$($PATH_CONVERT_BIN -w $CONF)

MIGRAW_YAML=$(find_migraw_yaml)
if [ "$MIGRAW_YAML" != "" ]; then
    eval "$(parse_yaml $MIGRAW_YAML MIGRAW_YAML_)"
    MIGRAW_CURRENT=$(dirname "$MIGRAW_YAML")/.migraw
    MIGRAW_CURRENT_BASE=$(dirname "$MIGRAW_YAML")
else
    MIGRAW_YAML_NOT_FOUND=1
    MIGRAW_CURRENT=$PWD/.migraw
    MIGRAW_CURRENT_BASE=$PWD
fi

if [ $MIGRAW_YAML_NOT_FOUND ]; then
    echo -e "\n${COLOR_RED}!!! migraw.yml|yaml not found !!!${COLOR_NC}"
fi

MIGRAW_CURRENT_WINDOWS=$($PATH_CONVERT_BIN -w $MIGRAW_CURRENT)
MIGRAW_CURRENT_BASE_WINDOWS=$($PATH_CONVERT_BIN -w $MIGRAW_CURRENT_BASE)

AVAILABLE_NODE_VERSIONS=("10" "12" "14")
NODE_VERSION=${AVAILABLE_NODE_VERSIONS[-1]}
if [ -n "$MIGRAW_YAML_config_node" ]; then
NODE_VERSION=$MIGRAW_YAML_config_node
fi

AVAILABLE_PHP_VERSIONS=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0")
PHP_VERSION=${AVAILABLE_PHP_VERSIONS[-1]}
PHP_VERSION=$MIGRAW_YAML_config_php

case $ACTION in
    up)
        ;&
    start)
        if [ -d "$MIGRAW_CURRENT" ]; then
          echo -e "\n${COLOR_RED}.migraw Folder exists, please delete it first (e.g. using migraw destroy).${COLOR_NC}"
          exit 1;
        fi
        echo -e "\n${COLOR_CYAN}Starting migraw${COLOR_NC}\n"
        update_hosts
        # https://askubuntu.com/a/357222
        execute_with_progress_spinner "start"
        INIT_SCRIPTS=("${MIGRAW_YAML_start[@]}" "${MIGRAW_YAML_init[@]}" "${MIGRAW_YAML_exec[@]}")
        for i in "${INIT_SCRIPTS[@]}"
          do :
          echo -e "\n${COLOR_CYAN}Executing:${COLOR_NC} $i\n"
          spawn_bash "$i"
        done
        ;;
    destroy)
        ;&
    stop)
        echo -e "\n${COLOR_RED}Are you sure to destroy th current instance (db instance data will be lost). (Yes or No) ${COLOR_NC}"
        are_you_sure
        set_path
        echo -e "\n${COLOR_CYAN}Stoping migraw.${COLOR_NC}\n"
        for i in "${MIGRAW_YAML_shutdown[@]}"
          do :
          echo -e "\n${COLOR_CYAN}Executing:${COLOR_NC} $i\n"
          spawn_bash "$i"
        done
        execute_with_progress_spinner "stop"
        clean
        ;;
    suspend)
        ;&
    pause)
        echo -e "\n${COLOR_CYAN}Pause migraw.${COLOR_NC}\n"
        execute_with_progress_spinner "stop"
        ;;
    resume)
        ;&
    unpause)
        echo -e "\n${COLOR_CYAN}Unpause migraw.${COLOR_NC}\n"
        execute_with_progress_spinner "unpause"
        ;;
    shell)
        set_path
        spawn_shell "$2"
        ;;
    bash)
        set_path
        spawn_bash "$2"
        ;;
    zsh)
        set_path
        spawn_zsh "$2"
        ;;
    update)
        ;&
    install)
        echo -e "\n${COLOR_RED}Are you sure to (re)install migraw? (Yes or No) ${COLOR_NC}"
        are_you_sure
        REQUIREMENTS=("wget" "unzip" "p7zip" "curl" )
        for REQUIREMENT in ${REQUIREMENTS[*]}
        do
            if ! [ -x "$(command -v $REQUIREMENT)" ]; then
                echo -e "\n${COLOR_RED}!!! Not all required packages are installed !!!${COLOR_NC}"
                echo -e "\n${COLOR_RED}!!! Make sure '${REQUIREMENTS[*]}' are installed !!!${COLOR_NC}"
                exit 1
            fi
        done
        echo -e "\n${COLOR_CYAN}Installing needed binaries and libaries.${COLOR_NC}\n"
        check_for_sudo
        execute_with_progress_spinner "install"
        ;;
    status)
        echo -e "\n${COLOR_CYAN}Current status [TODO].${COLOR_NC}\n"
        ;;
    self-update)
        ;&
    selfupdate)
        echo -e "\n${COLOR_CYAN}Trying to update migraw.${COLOR_NC}\n"
        self_update
        ;;
    init)
        migraw_init
        ;;
    info)
        info
        ;;
    *)
        usage
        ;;
esac
