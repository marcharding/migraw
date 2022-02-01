#!/usr/bin/env bash

VERSION="0.0.0.1-"$(cat "$0" | md5sum | cut -d ' ' -f 1 | cut -c1-8);

UPDATE_URL="https://raw.githubusercontent.com/marcharding/migraw/main-dpkg/migraw.sh";

# Colors
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

function create_file_php_ini {
    mkdir -p `dirname "$1"`

    cp -rf $BIN/usr/lib/php/$PHP_VERSION/php.ini-production $1

    sed -i "s|;session.save_path = \"/var/lib/php/sessions\"|session.save_path=$PHPRC/session|g" $1
    sed -i "s|;curl.cainfo =|curl.cainfo=$BIN/cacert.pem|g" $1
    sed -i "s|expose_php = Off|expose_php = ON|g" $1
    sed -i "s|error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT|error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED \& ~E_WARNING|g" $1
    sed -i "s|memory_limit = 128M|memory_limit = 1024M|g" $1
    sed -i "s|display_errors = Off|display_errors = On|g" $1
    sed -i "s|log_errors = On|log_errors = Off|g" $1
    sed -i "s|;realpath_cache_size = 4096k|realpath_cache_size = 8192k|g" $1
    sed -i "s|post_max_size = 8M|post_max_size = 512M|g" $1
    sed -i "s|;opcache.max_accelerated_files=10000|opcache.max_accelerated_files=65536|g" $1
    sed -i "s|;opcache.enable=1|opcache.enable=1|g" $1
    sed -i "s|;opcache.enable_cli=0|opcache.enable_cli=1|g" $1

    echo "upload_max_filesize = 512MB" >> $1

    mkdir -p $MIGRAW_CURRENT/php/tmp

    echo "upload_tmp_dir = $MIGRAW_CURRENT/php/tmp" >> $1
    echo "sys_temp_dir = $MIGRAW_CURRENT/php/tmp" >> $1
    echo "session.save_path = $MIGRAW_CURRENT/php/session" >> $1
    echo "curl.cainfo = $BIN/cacert.pem" >> $1
    echo "openssl.cafile = $BIN/cacert.pem" >> $1
    echo "max_input_vars = 4096" >> $1
    echo 'date.timezone= "Europe/Berlin"' >> $1

    case "$PHP_VERSION" in
        "8.1")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20210902
        ;;
        "8.0")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20200930
        ;;
        "7.4")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20190902
        ;;
        "7.3")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20180731
        ;;
        "7.2")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20170718
        ;;
        "7.1")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20160303
        ;;
        "7.0")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20151012
        ;;
        "5.6")
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20131226
        ;;
        *)
          PHP_EXTENSION_DIR=$BIN/usr/lib/php/20210902
    esac

    read -r -d "" EXT <<EOL
extension_dir = $PHP_EXTENSION_DIR
extension=bcmath.so
extension=calendar.so
extension=ctype.so
extension=curl.so
extension=dom.so
extension=exif.so
extension=fileinfo.so
extension=ftp.so
extension=gd.so
extension=gettext.so
extension=iconv.so
extension=imagick.so
extension=intl.so
$(
    if [ "$PHP_VERSION" != "8.0" ] && [ "$PHP_VERSION" != "8.1" ]; then
        echo "extension=json.so"
    fi
)
extension=mbstring.so
extension=sqlite3.so
extension=mysqlnd.so
extension=mysqli.so
extension=pdo.so
extension=pdo_mysql.so
extension=pdo_sqlite.so
extension=phar.so
extension=posix.so
extension=readline.so
extension=shmop.so
extension=simplexml.so
extension=soap.so
extension=sockets.so
extension=sysvmsg.so
extension=sysvsem.so
extension=sysvshm.so
extension=tokenizer.so
extension=xml.so
extension=xmlreader.so
extension=xmlwriter.so
extension=xsl.so
extension=zip.so
zend_extension=opcache.so
;zend_extension=xdebug.so
EOL

    LINE=$(grep -n 'extension_dir = "ext"' $1 | cut -d: -f 1)

    head -n $LINE $1 > $1".tmp"
    echo "$EXT" >> $1".tmp"
    tail -n $(($LINE+1)) $1 >> $1".tmp"
    mv $1".tmp" $1
}

function create_php_fpm_configs {
    mkdir -p `dirname "$1"`
    read -r -d "" FPM <<EOL
[global]
pid = $MIGRAW_CURRENT/php/fpm.pid
error_log = $MIGRAW_CURRENT/php/fpm.log

[www]
listen = $MIGRAW_CURRENT/php/fpm.sock
listen.owner = $USERNAME
listen.group = $USERNAME
pm = dynamic
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 4
pm.max_children = 24
EOL
echo "$FPM" > $1
}

function create_file_my_cnf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
[mysqld]
port                           = 3306
bind-address                   = $MIGRAW_YAML_network_ip
max_allowed_packet             = 512M
thread_stack                   = 512K
thread_cache_size              = 16
max_connections                = 256
query_cache_limit              = 0
query_cache_size               = 0
query_cache_type               = 0
sync_binlog                    = 0
innodb_doublewrite             = 0
sql_mode                       = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
key_buffer_size                = 24M
tmp_table_size                 = 64M
innodb_buffer_pool_size        = 512M
innodb_log_file_size           = 64M
innodb_flush_log_at_trx_commit = 2
skip-log-bin
skip-external-locking
skip-name-resolve
performance_schema
EOL
}

function create_file_virtual_host_conf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
<VirtualHost *:8080 *:80>
    AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root"
    <Directory "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
  <FilesMatch .php$>
      SetHandler "proxy:unix:$MIGRAW_CURRENT/php/fpm.sock|fcgi://localhost"
  </FilesMatch>
</VirtualHost>

<VirtualHost *:8050>
    AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$BIN/opt/adminer"
    <Directory "$BIN/opt/adminer">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
  <FilesMatch .php$>
      SetHandler "proxy:unix:$MIGRAW_CURRENT/php/fpm.sock|fcgi://localhost"
  </FilesMatch>
  <Location /server-status>
    SetHandler server-status
  </Location>
</VirtualHost>

<VirtualHost *:8443 *:443>
	AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root"
    SSLEngine on
    SSLCertificateFile "$MIGRAW_CURRENT/ssl/host.pem"
    SSLCertificateKeyFile "$MIGRAW_CURRENT/ssl/host-key.pem"
    <Directory "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
  <FilesMatch .php$>
      SetHandler "proxy:unix:$MIGRAW_CURRENT/php/fpm.sock|fcgi://localhost"
  </FilesMatch>
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
KeepAliveTimeout 2

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

<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>

# ****************************************************************************************************************
# MODULES

LoadModule access_compat_module $BIN/usr/lib/apache2/modules/mod_access_compat.so
LoadModule actions_module $BIN/usr/lib/apache2/modules/mod_actions.so
LoadModule alias_module $BIN/usr/lib/apache2/modules/mod_alias.so
LoadModule allowmethods_module $BIN/usr/lib/apache2/modules/mod_allowmethods.so
LoadModule asis_module $BIN/usr/lib/apache2/modules/mod_asis.so
LoadModule auth_basic_module $BIN/usr/lib/apache2/modules/mod_auth_basic.so
LoadModule authn_core_module $BIN/usr/lib/apache2/modules/mod_authn_core.so
LoadModule authn_file_module $BIN/usr/lib/apache2/modules/mod_authn_file.so
LoadModule authz_core_module $BIN/usr/lib/apache2/modules/mod_authz_core.so
LoadModule authz_groupfile_module $BIN/usr/lib/apache2/modules/mod_authz_groupfile.so
LoadModule authz_host_module $BIN/usr/lib/apache2/modules/mod_authz_host.so
LoadModule authz_user_module $BIN/usr/lib/apache2/modules/mod_authz_user.so
LoadModule autoindex_module $BIN/usr/lib/apache2/modules/mod_autoindex.so
LoadModule cgi_module $BIN/usr/lib/apache2/modules/mod_cgi.so
LoadModule dir_module $BIN/usr/lib/apache2/modules/mod_dir.so
LoadModule env_module $BIN/usr/lib/apache2/modules/mod_env.so
LoadModule include_module $BIN/usr/lib/apache2/modules/mod_include.so
LoadModule mpm_worker_module $BIN/usr/lib/apache2/modules/mod_mpm_worker.so
LoadModule status_module $BIN/usr/lib/apache2/modules/mod_status.so
LoadModule mime_module $BIN/usr/lib/apache2/modules/mod_mime.so
LoadModule negotiation_module $BIN/usr/lib/apache2/modules/mod_negotiation.so
LoadModule rewrite_module $BIN/usr/lib/apache2/modules/mod_rewrite.so
LoadModule setenvif_module $BIN/usr/lib/apache2/modules/mod_setenvif.so
LoadModule vhost_alias_module $BIN/usr/lib/apache2/modules/mod_vhost_alias.so
LoadModule headers_module $BIN/usr/lib/apache2/modules/mod_headers.so
LoadModule ssl_module $BIN/usr/lib/apache2/modules/mod_ssl.so
LoadModule proxy_module $BIN/usr/lib/apache2/modules/mod_proxy.so
LoadModule proxy_fcgi_module $BIN/usr/lib/apache2/modules/mod_proxy_fcgi.so

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

AcceptFilter https none
AcceptFilter http none

User $MIGRAW_USER
Group $MIGRAW_USER
EOL
}

function migraw_init {
    if [ ! -f  $MIGRAW_CURRENT_BASE/migraw.yml ]; then
    cat > $MIGRAW_CURRENT_BASE/migraw.yml << EOL
name: migraw.default
document_root: public
network:
	ip: 127.0.0.1
	host: migraw.default.com
config:
	php: ${AVAILABLE_PHP_VERSIONS[-1]}
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

    chmod + $MIGRAW_CURRENT_BASE/init.sh

    if [ ! -f $MIGRAW_CURRENT_BASE/destroy.sh ]; then
    cat > $MIGRAW_CURRENT_BASE/destroy.sh << EOL
# set -o xtrace
trap 'echo -e "\e[0;32m" && echo -ne $(date "+%Y-%m-%d %H:%M:%S") && echo " >> Executing: $BASH_COMMAND" && echo -e "\e[0m"' DEBUG
mysqldump -h127.0.0.1 --opt --hex-blob -uroot application -r application_$(date '+%Y%m%d_%H%M%S').sql
trap - DEBUG
EOL
    fi

    chmod + $MIGRAW_CURRENT_BASE/destroy.sh
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

function install {

    echo "Installing/Downloading."

    rm -rf $DOWNLOAD
    rm -rf $BIN

    mkdir -p $DOWNLOAD
    mkdir -p $BIN
    mkdir -p $BIN/opt

    cd $DOWNLOAD

    PKG=(
        "jq"
        "apache2"
        "apache2-bin"
        "mariadb-common"
        "mariadb-client"
        "mariadb-server"
    )

    for i in "${PKG[@]}"
    do
        apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $i | grep "^\w" | sort -u)
    done

    AVAILABLE_PHP_VERSIONS=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1")

    for PHP_VERSION in "${AVAILABLE_PHP_VERSIONS[@]}"
    do
        PKG=(
            "libapache2-mod-php$PHP_VERSION"
            "php$PHP_VERSION-bcmath"
            "php$PHP_VERSION-cli"
            "php$PHP_VERSION-common"
            "php$PHP_VERSION-curl"
            "php$PHP_VERSION-gd"
            "php$PHP_VERSION-gd"
            "php$PHP_VERSION-intl"
            "php$PHP_VERSION-json"
            "php$PHP_VERSION-mbstring"
            "php$PHP_VERSION-mysql"
            "php$PHP_VERSION-mysql"
            "php$PHP_VERSION-opcache"
            "php$PHP_VERSION-phpdbg"
            "php$PHP_VERSION-readline"
            "php$PHP_VERSION-soap"
            "php$PHP_VERSION-soap"
            "php$PHP_VERSION-sqlite3"
            "php$PHP_VERSION-xml"
            "php$PHP_VERSION-xsl"
            "php$PHP_VERSION-xsl"
            "php$PHP_VERSION-zip"
            "php$PHP_VERSION-imagick"
            "php$PHP_VERSION-xdebug"
            "php$PHP_VERSION-fpm"
        )

        for i in "${PKG[@]}"
        do
            apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances $i | grep "^\w" | sort -u)
        done
    done

    # extract files
    echo "Extracting..."
    for PACKAGE in $(ls $DOWNLOAD/*.deb); do dpkg -x $PACKAGE $BIN; done

    # Copy mime types to correct folder
    mkdir -p $BIN/etc/apache2/conf
    cp $BIN/etc/mime.types $BIN/etc/apache2/conf/mime.types

    # CA certificates
    wget -q -O $BIN/cacert.pem https://curl.haxx.se/ca/cacert.pem

    # Generate self signed ssl certificate
    mkdir -p $BIN/etc/apache2/conf/ssl
    HOST_KEY=$BIN/etc/apache2/conf/ssl/host.key
    HOST_CERT=$BIN/etc/apache2/conf/ssl/host.key
    openssl genrsa 4096 > $HOST_KEY
    chmod 400 $HOST_KEY
    openssl req -subj "/C=PE/ST=World/L=World/O=Migraw/OU=Migraw/CN=example.com" -new -x509 -nodes -sha256 -days 365 -key $HOST_KEY -out $HOST_CERT

    # MailHog
    wget -q -O $BIN/opt/MailHog_linux_amd64 https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64
    chmod +x $BIN/opt/MailHog_linux_amd64

    # mkcert
    wget -q -O $BIN/opt/mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-amd64
    chmod +x $BIN/opt/mkcert
    wget -q -O $BIN/opt/mkcert.exe https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-windows-amd64.exe
    chmod +x $BIN/opt/mkcert.exe

    # Node.js
    AVAILABLE_NODE_VERSIONS=("12" "14" "16")

    for NODE_VERSION in "${AVAILABLE_NODE_VERSIONS[@]}"
    do
        COMPLETE_NODE_VERSION_NAME=$(curl --silent https://nodejs.org/dist/latest-v$NODE_VERSION.x/ | grep -Po '(?<=href=")node-v[0-9\.]+-linux-x64\.tar\.gz[^"]*(?=")' | tr -d '\0')
        wget -q -O "$DOWNLOAD/$COMPLETE_NODE_VERSION_NAME" "https://nodejs.org/dist/latest-v$NODE_VERSION.x/$COMPLETE_NODE_VERSION_NAME"
        tar xfz $DOWNLOAD/$COMPLETE_NODE_VERSION_NAME -C $DOWNLOAD
        mv $DOWNLOAD/$(basename -- "$COMPLETE_NODE_VERSION_NAME" .tar.gz) $BIN/opt/node-$NODE_VERSION
    done

    # Adminer
    mkdir -p $BIN/opt/adminer
    wget -q -O $BIN/opt/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php
    wget -q -O $BIN/opt/adminer/plugin.php https://raw.githubusercontent.com/vrana/adminer/v4.8.1/plugins/plugin.php
    wget -q -O $BIN/opt/adminer/adminer.css https://raw.githubusercontent.com/decksterr/adminer-theme-dark/master/adminer.css
    read -r -d "" ADMINER <<EOL
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
echo "$ADMINER" >> $BIN/opt/adminer/index.php

    # composer
    PHP_VERSION="8.0"
    set_path
    $BIN/usr/bin/php8.0 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    $BIN/usr/bin/php8.0 composer-setup.php --install-dir=$BIN/usr/bin --filename=composer
    $BIN/usr/bin/php8.0 -r "unlink('composer-setup.php');"
}

function set_path {

    # Symlink binaries
    mkdir -p $MIGRAW_CURRENT/bin
    ln -rsf $BIN/usr/bin/php$PHP_VERSION $MIGRAW_CURRENT/bin/php
    ln -rsf $BIN/opt/node-$NODE_VERSION/bin/node $MIGRAW_CURRENT/bin/node
    ln -rsf $BIN/opt/node-$NODE_VERSION/bin/npm $MIGRAW_CURRENT/bin/npm

    # Composer home
    COMPOSER_HOME=$SCRIPT_BASE/migraw/var/migraw

    # set local binaries first
    PATH=$MIGRAW_CURRENT/bin:$PATH
    PATH=$BIN/usr/bin:"$PATH"
    PATH=$BIN/usr/sbin:"$PATH"
    PATH=$COMPOSER_HOME/vendor/bin:"$PATH"
    PATH=$BIN/opt:"$PATH"

    PATH=$MIGRAW_CURRENT/gem/bin:"$PATH"
    PATH=$MIGRAW_CURRENT_BASE/vendor/bin:"$PATH"
    PATH=$MIGRAW_CURRENT_BASE/node_modules/.bin:"$PATH"

    # Patch LD_LIBRARY_PATH so everything is self-contained
    LD_LIBRARY_PATH=$BIN/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

    # MariaDB socket
    MYSQL_UNIX_PORT=$MIGRAW_CURRENT/mysql/mysql.sock
    MYSQL_HOME=$MYSQL_HOME

    # PHP settings & folders
    PHPRC=$MIGRAW_CURRENT/php
    PHP_INI_SCAN_DIR=$MIGRAW_CURRENT/php
    mkdir -p $MIGRAW_CURRENT/php/session
    create_file_php_ini $MIGRAW_CURRENT/php/php.ini

    # Node.js settings & Folder
    # https://docs.npmjs.com/misc/config
    # export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
    NODE_PATH=$MIGRAW_CURRENT/node
    NPM_CONFIG_PREFIX=$MIGRAW_CURRENT/npm
    NPM_CONFIG_CACHE=$MIGRAW_CURRENT/npm/npm-cache
    NPM_CONFIG_USERCONFIG=$MIGRAW_CURRENT/npm

    # zsh shell home
    ZDOTDIR=$MIGRAW_CURRENT/shell

    export PATH
    export COMPOSER_HOME
    export LD_LIBRARY_PATH
    export MYSQL_UNIX_PORT
    export PHPRC
    export NPM_CONFIG_PREFIX
    export NPM_CONFIG_CACHE
    export NPM_CONFIG_USERCONFIG
    export NODE_PATH
    export ZDOTDIR

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

function copy_file_if_target_not_exists {
    if [ ! -f $2 ]; then
        cp -f $1 $1
    fi
}

function stop {

    if [ -f $MIGRAW_CURRENT/php/fpm.pid ]; then
        start-stop-daemon --stop --quiet --pidfile $MIGRAW_CURRENT/php/fpm.pid
    fi

    if [ -f $MIGRAW_CURRENT/mysql/mysql.pid ]; then
        kill -9 `cat "$MIGRAW_CURRENT/mysql/mysql.pid"`
        rm -rf $MIGRAW_CURRENT/mysql/mysql.pid
    fi

    if [ -f $MIGRAW_CURRENT/httpd/httpd.pid ]; then
        PID=`cat $MIGRAW_CURRENT/httpd/httpd.pid`
        for CHILD_PID in `pgrep -P $PID`
        do
            kill -9 $CHILD_PID
        done
        kill -9 $PID
        rm -rf $MIGRAW_CURRENT/httpd/httpd.pid
    fi

    if [ -f $MIGRAW_CURRENT/mailhog/mailhog.pid ]; then
        PID=`cat "$MIGRAW_CURRENT/mailhog/mailhog.pid"`
        if [ -e /proc/$PID/status ]; then
            kill -9 $PID
        fi
        rm -rf $MIGRAW_CURRENT/mailhog/mailhog.pid
    fi
}


function spawn_shell {
    set_path

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
    set_path

    PROMPT="\n${COLOR_PURPLE}\t ${MIGRAW_USER}@${MIGRAW_YAML_name}${COLOR_NC} [${COLOR_RED}\w${COLOR_NC}]${COLOR_NC}\n€${COLOR_NC} "

    if [ "$1" != "" ]; then
        env bash --rcfile <(echo 'PS1="'"$MIGRAW_USER@$MIGRAW_YAML_name"':\w\$ "') -c "$1"
    else
        env bash --rcfile <(echo 'PS1="'$(echo $PROMPT)' "')
    fi;
}

function spawn_zsh {
    set_path

    if [ "$1" != "" ]; then
        env zsh -c "$1"
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
        env zsh
    fi
}

function mailhog_start {
    if [ "$MIGRAW_YAML_config_mailhog" != "true" ]; then
        return
    fi
    mkdir -p $MIGRAW_CURRENT/mailhog/log
    $BIN/opt/MailHog_linux_amd64 > $MIGRAW_CURRENT/mailhog/log/mailhog.log 2>&1 & echo "$!" > $MIGRAW_CURRENT/mailhog/mailhog.pid
}

function mysql_start {
    if [ "$MIGRAW_YAML_config_mysql" != "true" ]; then
      return
    fi

    set_path

    BIN_MYSQLD="$BIN/usr/bin/mysqld_safe"

    # for wsl mysql stuff must be inside the wsl filesystem
    MYSQL_BASE_PATH=$MIGRAW_CURRENT/mysql

   if [ "$1" == "init" ]; then
       rm -rf $MYSQL_BASE_PATH
       mkdir -p $MYSQL_BASE_PATH/log
       mkdir -p $MYSQL_BASE_PATH/data $MYSQL_BASE_PATH/secure $MYSQL_BASE_PATH/tmp $MYSQL_BASE_PATH/log
       chmod -R 777 $MYSQL_BASE_PATH
       create_file_my_cnf $MYSQL_BASE_PATH/my.cnf
       chmod -R 777 $MYSQL_BASE_PATH
       chmod 655 $MYSQL_BASE_PATH/my.cnf
       "$BIN/usr/bin/mysql_install_db" --auth-root-authentication-method="normal" --basedir="$BIN/usr" --user="$USER" --lc-messages-dir="$BIN/usr/share/mysql" --datadir=$MYSQL_BASE_PATH/data > $MIGRAW_CURRENT/mysql/log/init.log 2>&1
   fi

    $BIN_MYSQLD \
     --defaults-file="$MYSQL_BASE_PATH/my.cnf" \
     --lc-messages-dir="$BIN/usr/share/mysql" \
     --log_error="$MIGRAW_CURRENT/mysql/log/log.err" \
     --pid_file="$MIGRAW_CURRENT/mysql/mysql.pid" \
     --basedir="$MYSQL_BASE_PATH" \
     --secure_file_priv="$MYSQL_BASE_PATH/secure" \
     --tmpdir="$MYSQL_BASE_PATH/tmp" \
     --datadir="$MYSQL_BASE_PATH/data" \
     --socket="$MYSQL_BASE_PATH/mysql.sock" \
     --user="$USER" >> $MIGRAW_CURRENT/mysql/log/init.log 2>&1 &

    counter=1
    while ! $BIN/usr/bin/mysql -h127.0.0.1 -uroot -e "show databases;" > /dev/null 2>&1; do
        sleep 1
        counter=`expr $counter + 1`
        if [ $counter -gt 30 ]; then
            echo "We have been waiting for MySQL too long already; failing."
            exit 1
        fi
    done

    return 0

}

function apache_start {

    if [ "$MIGRAW_YAML_config_apache" != "true" ]; then
      return
    fi

    set_path

    # start php fpm
    create_php_fpm_configs $MIGRAW_CURRENT/php/fpm.conf
    php-fpm$PHP_VERSION --fpm-config $MIGRAW_CURRENT/php/fpm.conf

    BIN_HTTPD="$BIN/usr/sbin/apache2"

    mkdir -p $MIGRAW_CURRENT/httpd $MIGRAW_CURRENT/httpd/log $MIGRAW_CURRENT/httpd/sites

    create_file_httpd_conf $MIGRAW_CURRENT/httpd/httpd.conf
    create_file_virtual_host_conf $MIGRAW_CURRENT/httpd/sites/default.conf

    mkdir -p $MIGRAW_CURRENT/ssl
    mkcert.exe -cert-file "$MIGRAW_CURRENT/ssl/host.pem" -key-file "$MIGRAW_CURRENT/ssl/host-key.pem" 127.0.0.1 $MIGRAW_YAML_network_host > $MIGRAW_CURRENT/ssl/mkcert.log 2>&1

    SERVER_NAME=$(echo "$MIGRAW_YAML_name" | iconv -t ascii//TRANSLIT | sed -E 's/[^a-zA-Z0-9-]+/-/g' | sed -E 's/^-+|-+$//g' | tr A-Z a-z)

    AUTHBIND_AVAILABLE=$(check_authbind_and_ports)

    read -r -d "" BIN_HTTPD_CMD <<EOL
        $(
            if [ -n "$AUTHBIND_AVAILABLE" ]; then
                echo "authbind"
            fi
        ) \
        $BIN_HTTPD \
            -f "$MIGRAW_CURRENT/httpd/httpd.conf" \
            -c "PidFile $MIGRAW_CURRENT/httpd/httpd.pid" \
            -c "ServerRoot $BIN/etc/apache2" \
            -c "ServerName $SERVER_NAME" \
            -c "ServerAdmin admin@$SERVER_NAME" \
            $(
                if [ -n "$AUTHBIND_AVAILABLE" ]; then
                    printf %s " -c \"Listen $MIGRAW_YAML_network_ip:8050\""
                    printf %s " -c \"Listen $MIGRAW_YAML_network_ip:80\""
                    printf %s " -c \"Listen $MIGRAW_YAML_network_ip:443 \""
                else
                    printf %s " -c \"Listen $MIGRAW_YAML_network_ip:8050\""
                    printf %s " -c \"Listen $MIGRAW_YAML_network_ip:8080\""
                    printf %s " -c \"Listen $MIGRAW_YAML_network_ip:8443 \""
                fi
            ) \
            -c "Include $MIGRAW_CURRENT/httpd/sites/*.conf" \
            -c "CustomLog  $MIGRAW_CURRENT/httpd/log/access.log common" \
            -c "ErrorLog $MIGRAW_CURRENT/httpd/log/error.log" &
EOL

    echo "$BIN_HTTPD_CMD" > $MIGRAW_CURRENT/httpd/cmd && chmod +x $MIGRAW_CURRENT/httpd/cmd
    $MIGRAW_CURRENT/httpd/cmd &

}

# see https://stackoverflow.com/a/38275644
function execute_with_progress_spinner {
    if [ "$OPTION" == "debug" ]; then
        $1
    else
        echo -ne "${COLOR_BROWN}Working "
        (while :; do for c in / - \\ \|; do printf '[%s]\b\b\b' "$c"; sleep 0.1; done; done) &
        touch $BASE/migraw.log
        chmod 777 $BASE/migraw.log
        SPINNER=$!
        {
            $1 > $BASE/migraw.log 2>&1
        }
        {
            echo -e "${COLOR_NC}\r${COLOR_PURPLE}Finished.         ";
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

    if mv -f "$0.tmp" "$FILE"; then
        echo -e "${COLOR_CYAN}Update complete.${COLOR_NC}\n"
    else
        echo -e "${COLOR_PURPLE}Update failed while moving update file.${COLOR_NC}\n"
    fi
}

function usage {

cat <<EOF

$(echo -e "${COLOR_CYAN}migraw/$VERSION${COLOR_NC}")

Usage:
  $(echo -e "${COLOR_CYAN}migraw${COLOR_NC}") [$(echo -e "${COLOR_GREEN}command${COLOR_NC}")] [$(echo -e "${COLOR_PURPLE}options${COLOR_NC}")]

Options:
  $(echo -e "${COLOR_PURPLE}--debug ${COLOR_NC}")           Show debug information

Commands:
  $(echo -e "${COLOR_GREEN}up|start${COLOR_NC}")            Start migraw instance.
  $(echo -e "${COLOR_GREEN}suspend|pause${COLOR_NC}")       Suspend migraw instance (data stays).
  $(echo -e "${COLOR_GREEN}resume|unpause${COLOR_NC}")      Resume migraw instance.
  $(echo -e "${COLOR_GREEN}bash [cmd]${COLOR_NC}")          Spawns a bash shell within the current migraw enviroment with an optional [cmd].
  $(echo -e "${COLOR_GREEN}zsh [cmd]${COLOR_NC}")           Spawns a zsh shell within the current migraw enviroment  with an optional [cmd].
  $(echo -e "${COLOR_GREEN}install${COLOR_NC}")             Install all binaries, can also be used to update.
  $(echo -e "${COLOR_GREEN}selfupdate${COLOR_NC}")          Update migraw
  $(echo -e "${COLOR_GREEN}init${COLOR_NC}")                Update create demo migraw.yml, init.sh and destroy.sh
  $(echo -e "${COLOR_GREEN}mkcert${COLOR_NC}")              Install root ssl certificates (only needed once)
  $(echo -e "${COLOR_GREEN}info${COLOR_NC}")                Display info and help

EOF

}

function update_hosts
{
    if [ $? == 0 ]; then
        if [ "$MIGRAW_YAML_network_host" != "" ]; then
            HOSTS=/mnt/c/System32/drivers/etc/hosts
            if ! grep -q "$MIGRAW_YAML_network_host" $HOSTS; then
                check_for_sudo
                check_for_sudo echo "127.0.0.1 $MIGRAW_YAML_network_host" >> $HOSTS
            fi
        fi
    fi
}

function install_mkcert
{
    set_path
    WIN_USERNAME="$(powershell.exe '[Environment]::UserName')"
    WIN_USERNAME=${WIN_USERNAME//[^[:alnum:]._-]/}
    mkcert.exe -install
    export CAROOT=/mnt/c/Users/$WIN_USERNAME/AppData/Local/mkcert
    mkcert -install
}

function check_for_sudo {
    if ! sudo -n true 2>/dev/null; then
        sudo -v
        echo ""
    fi
}

function check_authbind_and_ports {
    if command -v authbind &> /dev/null; then
        if [[ -x /etc/authbind/byport/80 && -x /etc/authbind/byport/443 ]];
            then echo "Authbind available and ports forwarded"
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

ACTION=$1

OPTION="${2//-}"

# base dir
BASE="$( cd "$(dirname "$0")" ; pwd -P )"

# script origin base dir
SCRIPT_BASE="$(dirname "$(readlink -f "$0")")"

# migraw user
if [ "$SUDO_USER" != "" ]; then
    MIGRAW_USER=$SUDO_USER
else
    MIGRAW_USER=$USER
fi

# download dir
DOWNLOAD=$SCRIPT_BASE/migraw-data/download

# bin base
BIN=$SCRIPT_BASE/migraw-data/bin

# .migraw base
MIGRAW_BASE=$BASE/.migraw

MIGRAW_YAML=$(find_migraw_yaml)
if [ "$MIGRAW_YAML" != "" ]; then
    eval "$(parse_yaml $MIGRAW_YAML MIGRAW_YAML_)"
    MIGRAW_CURRENT=$(dirname "$MIGRAW_YAML")/.migraw
    MIGRAW_CURRENT_BASE=$(dirname "$MIGRAW_YAML")
else
    MIGRAW_CURRENT=$PWD/.migraw
    MIGRAW_CURRENT_BASE=$PWD
fi

AVAILABLE_PHP_VERSIONS=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1")
PHP_VERSION=${AVAILABLE_PHP_VERSIONS[-1]}
if [ "$MIGRAW_YAML_config_php" != "" ]; then
    PHP_VERSION=$MIGRAW_YAML_config_php
fi

AVAILABLE_NODE_VERSIONS=("12" "14" "16")
NODE_VERSION=${AVAILABLE_NODE_VERSIONS[-1]}
if [ "$MIGRAW_YAML_config_node" != "" ]; then
    NODE_VERSION=$MIGRAW_YAML_config_node
fi

MIGRAW_CURRENT_HASH=$(echo $MIGRAW_CURRENT | md5sum | cut -d" " -f1)
MIGRAW_CURRENT_HASH=${MIGRAW_YAML_name}_${MIGRAW_CURRENT_HASH:0:8}

case $ACTION in
    up)
        ;&
    start)
        if [ -d "$MIGRAW_CURRENT" ]; then
          echo -e "\n${COLOR_RED}.migraw Folder exists, please delete it first (e.g. using migraw destroy).${COLOR_NC}"
          exit 1;
        fi
        echo -e "\n${COLOR_CYAN}Starting migraw${COLOR_NC}\n"
        # https://askubuntu.com/a/357222
        execute_with_progress_spinner "start"
        for i in "${MIGRAW_YAML_exec[@]}"
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
    redir)
        setup_port_redirect
        port
        ;;
    update)
        ;&
    install)
        echo -e "\n${COLOR_CYAN}Installing needed binaries and libaries.${COLOR_NC}\n"
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
    mkcert)
        install_mkcert
        ;;
    info)
        info
        ;;
    *)
        usage
        ;;
esac
