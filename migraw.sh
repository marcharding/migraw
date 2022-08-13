#!/usr/bin/env zsh

# build version string (TODO: create from commit?)
VERSION="0.0.0.1-"$(basename "$0.tmp" | md5sum | cut -d ' ' -f 1 | cut -c1-8);

# update urls
UPDATE_URL="https://raw.githubusercontent.com/marcharding/migraw/osx/migraw.sh";

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

function create_file_php_ini {
    mkdir -p `dirname "$1"`

    cp -rf $PHP_HOME/.bottle/etc/php/$PHP_VERSION/php.ini $1

    perl -i -pe "s|max_execution_time = 30|max_execution_time = 900|g" $1
    perl -i -pe "s|expose_php = Off|expose_php = On|g" $1
    perl -i -pe "s|error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT|error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED \& ~E_WARNING|g" $1
    perl -i -pe "s|memory_limit = 128M|memory_limit = 1024M|g" $1
    perl -i -pe "s|display_errors = Off|display_errors = On|g" $1
    perl -i -pe "s|display_startup_errors = Off|display_startup_errors = On|g" $1
    perl -i -pe "s|log_errors = On|log_errors = Off|g" $1
    perl -i -pe "s|;realpath_cache_size = 4096k|realpath_cache_size = 2M|g" $1
    perl -i -pe "s|post_max_size = 8M|post_max_size = 512M|g" $1
    perl -i -pe "s|;opcache.max_accelerated_files=10000|opcache.max_accelerated_files=32768|g" $1

    echo "upload_max_filesize = 512M" >> $1

    mkdir -p $MIGRAW_CURRENT/php/tmp

    echo "upload_tmp_dir = $MIGRAW_CURRENT/php/tmp" >> $1
    echo "sys_temp_dir = $MIGRAW_CURRENT/php/tmp" >> $1
    echo "session.save_path = $MIGRAW_CURRENT/php/session" >> $1
    echo "max_input_vars = 4096" >> $1
    echo 'date.timezone= "Europe/Berlin"' >> $1  
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
sync_binlog                    = 0
# sql_mode see follwing links
# https://stackoverflow.com/a/40303542
# https://www.devside.net/wamp-server/mysql-error-incorrect-integer-value-for-column-name-at-row-1
sql_mode                       = "ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
tmp_table_size                 = 64M
innodb_buffer_pool_size        = 512M
innodb_log_file_size           = 256M
innodb_flush_log_at_trx_commit = 2
innodb_read_io_threads         = 8
innodb_write_io_threads        = 8
character-set-server           = utf8mb4
skip-log-bin
skip-external-locking
sort_buffer_size               = 16777216
wait_timeout                   = 3600

[client]
default-character-set          = utf8mb4
EOL
}

function create_file_virtual_host_conf {

    mkdir -p `dirname "$1"`
    rm -rf $1

    if [ "$(id -u)" != 0 ]; then
    cat >> $1 << EOL
<VirtualHost *:8080>
    AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root"
    <Directory "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
</VirtualHost>
EOL
    else
    cat >> $1 << EOL
<VirtualHost *:80>
    AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root"
    <Directory "$MIGRAW_CURRENT_BASE/$MIGRAW_YAML_document_root">
        AllowOverride All
        Options FollowSymLinks Indexes
    </Directory>
</VirtualHost>
EOL
    fi

    cat >> $1 << EOL
<VirtualHost *:8050>
    AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$ADMINER_HOME"
    <Directory "$ADMINER_HOME">
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

LoadModule access_compat_module $APACHE_HOME/lib/httpd/modules/mod_access_compat.so
LoadModule actions_module $APACHE_HOME/lib/httpd/modules/mod_actions.so
LoadModule alias_module $APACHE_HOME/lib/httpd/modules/mod_alias.so
LoadModule allowmethods_module $APACHE_HOME/lib/httpd/modules/mod_allowmethods.so
LoadModule asis_module $APACHE_HOME/lib/httpd/modules/mod_asis.so
LoadModule auth_basic_module $APACHE_HOME/lib/httpd/modules/mod_auth_basic.so
LoadModule authn_core_module $APACHE_HOME/lib/httpd/modules/mod_authn_core.so
LoadModule authn_file_module $APACHE_HOME/lib/httpd/modules/mod_authn_file.so
LoadModule authz_core_module $APACHE_HOME/lib/httpd/modules/mod_authz_core.so
LoadModule authz_groupfile_module $APACHE_HOME/lib/httpd/modules/mod_authz_groupfile.so
LoadModule authz_host_module $APACHE_HOME/lib/httpd/modules/mod_authz_host.so
LoadModule authz_user_module $APACHE_HOME/lib/httpd/modules/mod_authz_user.so
LoadModule autoindex_module $APACHE_HOME/lib/httpd/modules/mod_autoindex.so
LoadModule cgi_module $APACHE_HOME/lib/httpd/modules/mod_cgi.so
LoadModule dir_module $APACHE_HOME/lib/httpd/modules/mod_dir.so
LoadModule env_module $APACHE_HOME/lib/httpd/modules/mod_env.so
LoadModule include_module $APACHE_HOME/lib/httpd/modules/mod_include.so
LoadModule mime_module $APACHE_HOME/lib/httpd/modules/mod_mime.so
LoadModule negotiation_module $APACHE_HOME/lib/httpd/modules/mod_negotiation.so
LoadModule rewrite_module $APACHE_HOME/lib/httpd/modules/mod_rewrite.so
LoadModule setenvif_module $APACHE_HOME/lib/httpd/modules/mod_setenvif.so
LoadModule vhost_alias_module $APACHE_HOME/lib/httpd/modules/mod_vhost_alias.so
LoadModule headers_module $APACHE_HOME/lib/httpd/modules/mod_headers.so
LoadModule ssl_module $APACHE_HOME/lib/httpd/modules/mod_ssl.so
LoadModule unixd_module $APACHE_HOME/lib/httpd/modules/mod_unixd.so
LoadModule mpm_prefork_module $APACHE_HOME/lib/httpd/modules/mod_mpm_prefork.so
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
# composer install
# npm install
# mysql -h127.0.0.1 -uroot -e "CREATE DATABASE application"
# mysql -h127.0.0.1 -uroot application < application.sql
trap - DEBUG
EOL
    fi
    chmod +x $MIGRAW_CURRENT_BASE/init.sh
    if [ ! -f  $MIGRAW_CURRENT_BASE/destroy.sh ]; then
    cat > $MIGRAW_CURRENT_BASE/destroy.sh << EOL
# set -o xtrace
trap 'echo -e "\e[0;32m" && echo -ne $(date "+%Y-%m-%d %H:%M:%S") && echo " >> Executing: $BASH_COMMAND" && echo -e "\e[0m"' DEBUG
# mysqldump -h127.0.0.1  --opt -uroot application -r application_$(date '+%Y%m%d_%H%M%S').sql
trap - DEBUG
EOL
    fi
    chmod +x $MIGRAW_CURRENT_BASE/destroy.sh
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

    set_path

    $HOMEBREW_HOME/bin/brew tap shivammathur/php

    $HOMEBREW_HOME/bin/brew install wget
    $HOMEBREW_HOME/bin/brew install curl
    $HOMEBREW_HOME/bin/brew install md5sha1sum

    $HOMEBREW_HOME/bin/brew install shivammathur/php/php@7.2
    $HOMEBREW_HOME/bin/brew install shivammathur/php/php@7.3
    $HOMEBREW_HOME/bin/brew install shivammathur/php/php@7.4
    $HOMEBREW_HOME/bin/brew install shivammathur/php/php@8.0
    # TODO: Add a check for reinstalling/updating

    $HOMEBREW_HOME/bin/brew install httpd

    $HOMEBREW_HOME/bin/brew install mysql@5.7
    $HOMEBREW_HOME/bin/brew install mysql@8.0
    $HOMEBREW_HOME/bin/brew install mariadb@10.3

    $HOMEBREW_HOME/bin/brew install node@12
    $HOMEBREW_HOME/bin/brew install node@14
    $HOMEBREW_HOME/bin/brew install node@16
    $HOMEBREW_HOME/bin/brew install node@18

    # $HOMEBREW_HOME/bin/brew install imagemagik

    wget https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types -O $MIGRAW_HOME/mime.types

    # adminer
    mkdir -p $MIGRAW_HOME/adminer
    wget -q -O $MIGRAW_HOME/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php
    wget -q -O $MIGRAW_HOME/adminer/plugin.php https://raw.githubusercontent.com/vrana/adminer/v4.8.1/plugins/plugin.php
    wget -q -O $MIGRAW_HOME/adminer/adminer.css https://raw.githubusercontent.com/decksterr/adminer-theme-dark/master/adminer.css
read -r -d "" ADMINER_PATCH <<EOL
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
echo "$ADMINER_PATCH" > $MIGRAW_HOME/adminer/index.php

}

function set_path {

    # homebrew home for apple silicon arch
    HOMEBREW_HOME=/opt/homebrew
    MIGRAW_HOME=/Users/"$USER"/migraw
    ADMINER_HOME=$MIGRAW_HOME/adminer

    PHP_HOME=$HOMEBREW_HOME/opt/php@$PHP_VERSION/
    MYSQL_HOME=$HOMEBREW_HOME/opt/mariadb@10.3/
    NODE_HOME=$HOMEBREW_HOME/opt/node@$NODE_VERSION
    NPM_CONFIG_PREFIX=$NODE_HOME/lib/node_modules
    APACHE_HOME=$HOMEBREW_HOME/opt/httpd
    MIME_TYPES=$MIGRAW_HOME/mime.types
    MAILHOG=$HOMEBREW_HOME/opt/mailhog/bin/MailHog

    PATH=$MIGRAW_CURRENT_BASE/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/vendor/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/node_modules/.bin:$PATH
    PATH=$MIGRAW_CURRENT/gem/bin:$PATH
    PATH=$MIGRAW_CURRENT/bin:$PATH

    PHP_INI_SCAN_DIR=$MIGRAW_CURRENT
    PHPRC=$MIGRAW_CURRENT/php

    PATH=$MYSQL_HOME/bin:$NODE_HOME/lib/node_modules/bin:$NODE_HOME/bin:$PATH

    mkdir -p $HOME/.composer
    COMPOSER_HOME=$HOME/.composer

    mkdir -p $MIGRAW_CURRENT/php/session
    create_file_php_ini $MIGRAW_CURRENT/php/php.ini

    export HOMEBREW_HOME
    export MIGRAW_HOME
    export ADMINER_HOME

    export PHP_HOME
    export MYSQL_HOME
    export NODE_HOME
    export NPM_CONFIG_PREFIX
    export APACHE_HOME
    export MIME_TYPES
    export MAILHOG

    export PATH
    export COMPOSER_HOME
    export PHPRC
    export PHP_INI_SCAN_DIR
    export MYSQL_HOME

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

function kill_process_by_pid_file {
    if [ -f $1 ]; then
        PID=`cat "$1" | tr -dc '0-9'`
        kill -9 $PID
        rm -rf $1
    fi
}

function kill_apache {
    FILE=$MIGRAW_CURRENT/httpd/httpd.pid
    if [ -f $FILE ]; then
        kill -TERM `cat $FILE`
        rm -rf $FILE
    fi
}

function stop {
    kill_process_by_pid_file $MIGRAW_CURRENT/mysql/mysql.pid
    kill_apache
    kill_process_by_pid_file $MIGRAW_CURRENT/mailhog/mailhog.pid
}

function prepare_shell {

    mkdir -p $MIGRAW_CURRENT/bin

cat > $MIGRAW_CURRENT/bin/php << EOL
    $PHP_HOME/bin/php "\$@"
EOL
chmod +x $MIGRAW_CURRENT/bin/php

cat > $MIGRAW_CURRENT/bin/composer << EOL
    $PHP_HOME/bin/php /opt/homebrew/opt/composer/bin/composer "\$@"
EOL
chmod +x $MIGRAW_CURRENT/bin/composer

cat > $MIGRAW_CURRENT/bin/node << EOL
    $NODE_HOME/bin/node "\$@"
EOL
chmod +x $MIGRAW_CURRENT/bin/node

cat > $MIGRAW_CURRENT/bin/npm << EOL
    $NODE_HOME/lib/node_modules/bin/npm "\$@"
EOL
chmod +x $MIGRAW_CURRENT/bin/npm

}

function spawn_zsh {
    prepare_shell

    if [ "$1" != "" ]; then
        env -i WSLENV=$WSLENV PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH COMPOSER_HOME=$COMPOSER_HOME NODE_HOME=$NODE_HOME NPM_CONFIG_PREFIX=$NPM_CONFIG_PREFIX HOME=$HOME zsh "$1"
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
        env -i ZDOTDIR=$MIGRAW_CURRENT/shell WSLENV=$WSLENV PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH COMPOSER_HOME=$COMPOSER_HOME NODE_HOME=$NODE_HOME NPM_CONFIG_PREFIX=$NPM_CONFIG_PREFIX HOME=$HOME zsh
    fi
}

function mailhog_start {
    mkdir -p $MIGRAW_CURRENT/mailhog/log
    $MAILHOG > $MIGRAW_CURRENT/mailhog/log/mailhog.log 2>&1 & echo "$!" > $MIGRAW_CURRENT/mailhog/mailhog.pid
}

# TOOD: Add support for mysql and mariadb
function mysql_start_old {

    BIN_MYSQL=./bin/mysqld_safe

    MYSQL_BASE_PATH=$MIGRAW_CURRENT/mysql

    if [ "$1" = "init" ]; then
        rm -rf $MYSQL_BASE_PATH
        mkdir -p $MYSQL_BASE_PATH/data $MYSQL_BASE_PATH/secure $MYSQL_BASE_PATH/tmp $MYSQL_BASE_PATH/log
        create_file_my_cnf $MYSQL_BASE_PATH/my.cnf
        ( cd $MYSQL_HOME && ./bin/mysqld --initialize-insecure --datadir=$MYSQL_BASE_PATH/data 2>&1 > $MYSQL_BASE_PATH/log/log.init)
    fi

    ( cd $MYSQL_HOME && ./bin/mysqld \
    --defaults-file="$MYSQL_BASE_PATH/my.cnf" \
    --log-error="$MYSQL_BASE_PATH/log/log.err" \
    --pid-file="$MYSQL_BASE_PATH/mysql.pid" \
    --tmpdir="$MYSQL_BASE_PATH/tmp" \
    --datadir="$MYSQL_BASE_PATH/data" ) &

    counter=1
    while ! $MYSQL_HOME/bin/mysql -h127.0.0.1 -uroot -e "show databases;" > /dev/null 2>&1; do
        sleep 1
        counter=`expr $counter + 1`
        if [ $counter -gt 30 ]; then
            echo "We have been waiting for MySQL too long already; failing."
            exit 1
        fi
    done

}

function mysql_start {
    if [ "$MIGRAW_YAML_config_mysql" != "true" ]; then
      return
    fi

    set_path

    BIN_MYSQLD="/opt/homebrew/opt/mariadb@10.3/bin/mysqld_safe"

    # for wsl mysql stuff must be inside the wsl filesystem
    MYSQL_BASE_PATH=$MIGRAW_CURRENT/mysql

   if [ "$1" = "init" ]; then
       rm -rf $MYSQL_BASE_PATH
       mkdir -p $MYSQL_BASE_PATH/log
       mkdir -p $MYSQL_BASE_PATH/data $MYSQL_BASE_PATH/secure $MYSQL_BASE_PATH/tmp $MYSQL_BASE_PATH/log
       chmod -R 777 $MYSQL_BASE_PATH
       create_file_my_cnf $MYSQL_BASE_PATH/my.cnf
       chmod -R 777 $MYSQL_BASE_PATH
       chmod 655 $MYSQL_BASE_PATH/my.cnf
       
       "/opt/homebrew/opt/mariadb@10.3/bin/mysql_install_db" --auth-root-authentication-method="normal" --basedir="$MYSQL_HOME" --user="$USER" --lc-messages-dir="$MYSQL_HOME/share/mysql" --datadir=$MYSQL_BASE_PATH/data > $MIGRAW_CURRENT/mysql/log/init.log 2>&1
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
    while ! /opt/homebrew/opt/mariadb@10.3/bin/mysql -h127.0.0.1 -uroot -e "show databases;" > /dev/null 2>&1; do
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

    mkdir -p $MIGRAW_CURRENT/httpd $MIGRAW_CURRENT/httpd/log $MIGRAW_CURRENT/httpd/sites

    create_file_httpd_conf $MIGRAW_CURRENT/httpd/httpd.conf
    create_file_virtual_host_conf $MIGRAW_CURRENT/httpd/sites/default.conf

    read -r -d "" BIN_HTTPD_CMD <<EOL
        $APACHE_HOME/bin/httpd \
        -f "$MIGRAW_CURRENT/httpd/httpd.conf" \
        -DDEVELOPMENT \
        -DMIGRAW \
        -c "PidFile $MIGRAW_CURRENT/httpd/httpd.pid" \
        -c "ServerRoot $APACHE_HOME" \
        -c "ServerName $MIGRAW_YAML_name" \
        -c "ServerAdmin admin@$MIGRAW_YAML_name" \
        $(
            if [ "$(id -u)" != 0 ];
            then
                echo " -c \"Listen $MIGRAW_YAML_network_ip:8080\" -c \"Listen $MIGRAW_YAML_network_ip:8443\""
            else
                echo " -c \"Listen $MIGRAW_YAML_network_ip:80\" -c \"Listen $MIGRAW_YAML_network_ip:443\""
            fi
        ) \
        -c "Listen $MIGRAW_YAML_network_ip:8050" \
        -c "Include $MIGRAW_CURRENT/httpd/sites/*.conf" \
        -c "ErrorLog $MIGRAW_CURRENT/httpd/log/error.log" \
        -c "TypesConfig $MIME_TYPES" \
        $(
            if  [[ ${PHP_VERSION:0:1} == 8 ]];
            then
                echo " -c \"LoadModule php_module $PHP_HOME/lib/httpd/modules/libphp.so\""
            else
                echo " -c \"LoadModule php${PHP_VERSION:0:1}_module $PHP_HOME/lib/httpd/modules/libphp${PHP_VERSION:0:1}.so\""
            fi
        ) \
        -c "PHPIniDir $MIGRAW_CURRENT/php" &
EOL

echo "$BIN_HTTPD_CMD" | tr -s ' ' > $MIGRAW_CURRENT/httpd/httpd.start
chmod +x $MIGRAW_CURRENT/httpd/httpd.start
$MIGRAW_CURRENT/httpd/httpd.start

}

# see https://stackoverflow.com/a/38275644
function execute_with_progress_spinner {
    if [ "$OPTION" = "debug" ]; then
        $1
    else
        echo -ne "${COLOR_BROWN}Working ${COLOR_NC}"
        (while :; do for c in / - / \|; do printf "${COLOR_BROWN}[%s]${COLOR_NC}" "$c"; sleep 0.1; printf '\b\b\b'; done; done) &
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
    FILE=$(readlink "$0")

    if ! wget --quiet --output-document="$0.tmp" $UPDATE_URL ; then
        echo -e "${COLOR_PURPLE}Error while trying to download the update.${COLOR_NC}\n"
        exit 1
    fi

    CURRENT_VERSION_MD5=$(basename "$FILE" | md5sum | cut -d ' ' -f 1)
    NEW_VERSION_MD5=$(basename "$0.tmp" | md5sum | cut -d ' ' -f 1)
    if [ $CURRENT_VERSION_MD5 = $NEW_VERSION_MD5 ]; then
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

$(echo -e "${COLOR_CYAN}migraw/$OSTYPE/$(arch) $VERSION${COLOR_NC}")

Usage:
  $(echo -e "${COLOR_CYAN}migraw${COLOR_NC}") [$(echo -e "${COLOR_GREEN}command${COLOR_NC}")] [$(echo -e "${COLOR_PURPLE}options${COLOR_NC}")]

Options:
  $(echo -e "${COLOR_PURPLE}--debug${COLOR_NC}")             Show debug information

Commands:
  $(echo -e "${COLOR_GREEN}up|start${COLOR_NC}")            Start migraw instance.
  $(echo -e "${COLOR_GREEN}suspend|pause${COLOR_NC}")       Suspend migraw instance (data stays).
  $(echo -e "${COLOR_GREEN}resume|unpause${COLOR_NC}")      Resume migraw instance.
  $(echo -e "${COLOR_GREEN}zsh${COLOR_NC}")                 Spawns a zsh within the current migraw enviroment.
  $(echo -e "${COLOR_GREEN}zsh [cmd]${COLOR_NC}")           Runs [cmd] within the current migraw enviroment.
  $(echo -e "${COLOR_GREEN}install${COLOR_NC}")             Install all binaries, can also be used to update.
  $(echo -e "${COLOR_GREEN}selfupdate${COLOR_NC}")          Update migraw
  $(echo -e "${COLOR_GREEN}init${COLOR_NC}")                Update create demo migraw.yml, init.sh and destroy.sh
  $(echo -e "${COLOR_GREEN}info${COLOR_NC}")                Display info and help
EOF

}

function info {

cat <<EOF

$(echo -e "${COLOR_CYAN}Help and info for running migraw.${COLOR_NC}")

Coming soon.
EOF

}

function update_hosts
{
    if [ "$MIGRAW_YAML_network_host" != "" ]; then
        HOSTS=/etc/hosts 
        if ! grep -q "$MIGRAW_YAML_network_host" $HOSTS; then
            if [ "$(id -u)" != 0 ]; then
                echo -e "${COLOR_PURPLE}No root, hosts will not be updated.${COLOR_NC}\n"
            else
                echo "127.0.0.1 $MIGRAW_YAML_network_host" >> $HOSTS
            fi
        fi
    fi
}

function are_you_sure
{
    echo ""
    read -q "REPLY?y/n "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
    echo ""
}

ACTION=$1

OPTION="${2//-}"

# base dir
BASE="$( cd "$(dirname "$0")" ; pwd -P )"

# .migraw base
MIGRAW_BASE=$BASE/.migraw

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

MIGRAW_CURRENT=$MIGRAW_CURRENT

AVAILABLE_NODE_VERSIONS=("12" "14")
NODE_VERSION=${AVAILABLE_NODE_VERSIONS[-1]}
if [ -n "$MIGRAW_YAML_config_node" ]; then
    NODE_VERSION=$MIGRAW_YAML_config_node
fi

AVAILABLE_PHP_VERSIONS=("7.2" "7.4" "8.0")
PHP_VERSION=${AVAILABLE_PHP_VERSIONS[-1]}
if [ -n "$MIGRAW_YAML_config_php" ]; then
    PHP_VERSION=$MIGRAW_YAML_config_php
fi

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
        if [ "$(id -u)" != 0 ]; then
            echo -e "${COLOR_PURPLE}No root, apache will start on Port 8080 and 8443.${COLOR_NC}\n"
        fi
        # https://askubuntu.com/a/357222
        execute_with_progress_spinner "start"
        INIT_SCRIPTS=("${MIGRAW_YAML_start[@]}" "${MIGRAW_YAML_init[@]}" "${MIGRAW_YAML_exec[@]}")
        for i in "${INIT_SCRIPTS[@]}"
          do :
          if [[ ! -z "$i" ]]; then
            echo -e "\n${COLOR_CYAN}Executing:${COLOR_NC} $i"
            spawn_zsh "$i"
          fi;  
        done
        ;;
    destroy)
        ;&
    stop)
        echo -e "\n${COLOR_RED}Are you sure to destroy th current instance (db instance data will be lost). (Yes or No) ${COLOR_NC}"
        are_you_sure
        set_path
        echo -e "\n${COLOR_CYAN}Stoping migraw.${COLOR_NC}"
        for i in "${MIGRAW_YAML_shutdown[@]}"
          do :
          if [[ ! -z "$i" ]]; then
            echo -e "\n${COLOR_CYAN}Executing:${COLOR_NC} $i"
            spawn_zsh "$i"
          fi;  
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
        if [ "$(id -u)" != 0 ]; then
            echo -e "${COLOR_PURPLE}No root, apache will start on Port 8080 and 8443.${COLOR_NC}\n"
        fi
        execute_with_progress_spinner "unpause"
        ;;
    shell)
        set_path
        spawn_zsh "$2"
        ;;
    bash)
        set_path
        spawn_zsh "$2"
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
    info)
        info
        ;;
    *)
        usage
        ;;
esac
