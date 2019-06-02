#!/usr/bin/env bash

VERSION="0.0.0.1-"$(basename "$0.tmp" | md5sum | cut -d ' ' -f 1 | cut -c1-8);

UPDATE_URL="https://raw.githubusercontent.com/marcharding/migraw/bash-win64/migraw.sh";

if [[ `uname -s` == CYGWIN* ]]; then
    PATH_CONVERT_BIN="cygpath"
else
    PATH_CONVERT_BIN="wslpath"
fi;

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

    cp -rf $BIN/php-$PHP_VERSION/php.ini-production $1

    sed -i "s|max_execution_time = 30|max_execution_time = 720|g" $1
    sed -i "s|expose_php = Off|expose_php = On|g" $1
    sed -i "s|error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT|error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED \& ~E_WARNING|g" $1
    sed -i "s|memory_limit = 128M|memory_limit = 1024M|g" $1
    sed -i "s|display_errors = Off|display_errors = On|g" $1
    sed -i "s|display_startup_errors = Off|display_startup_errors = On|g" $1
    sed -i "s|log_errors = On|log_errors = Off|g" $1
    sed -i "s|;realpath_cache_size = 4096k|realpath_cache_size = 4096k|g" $1
    sed -i "s|post_max_size = 8M|post_max_size = 512M|g" $1
    sed -i "s|;opcache.max_accelerated_files=10000|opcache.max_accelerated_files=32768|g" $1

    echo "upload_max_filesize = 512M" >> $1

    mkdir -p $MIGRAW_CURRENT/php/tmp

    echo "upload_tmp_dir = $MIGRAW_CURRENT_WINDOWS\\php\\tmp" >> $1
    echo "session.save_path = $MIGRAW_CURRENT_WINDOWS\\php\\session" >> $1
    echo "curl.cainfo = $BIN_WIN\\cacert.pem" >> $1

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
extension=php_gd2.dll
extension=php_gettext.dll
extension=php_gmp.dll
$(
    if [ "$PHP_VERSION" != "5.6" ]; then
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
;extension=php_sodium.dll
extension=php_sqlite3.dll
extension=php_tidy.dll
extension=php_xmlrpc.dll
extension=php_xsl.dll
$(
    if [ "$PHP_VERSION" != "5.6" ]; then
        echo "extension=php_apcu.dll"
    fi
)
zend_extension=php_opcache.dll
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
flush_time                     = 180
log_error_verbosity            = 1
port                           = 3306
bind-address                   = $MIGRAW_YAML_network_ip
key_buffer_size                = 128M
max_allowed_packet             = 128M
thread_stack                   = 256K
thread_cache_size              = 16
max_connections                = 256
query_cache_limit              = 8M
query_cache_size               = 64M
sync_binlog                    = 0
sql_mode                       = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
tmp_table_size                 = 64M
innodb_buffer_pool_size        = 512M
innodb_log_file_size           = 256M
innodb_flush_log_at_trx_commit = 2
innodb_read_io_threads         = 8
innodb_write_io_threads        = 8
innodb_thread_concurrency      = 0
skip-log-bin
skip-external-locking

[client]
default-character-set=utf8
EOL
}

function create_file_virtual_host_conf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
<VirtualHost *:*>
	AcceptPathInfo On
    UseCanonicalName Off
    ServerAlias *
    DocumentRoot "$MIGRAW_CURRENT_BASE_WINDOWS/$MIGRAW_YAML_document_root"
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

EOL
}

function find_migraw_yaml {
    x=`pwd`;
    while [ "$x" != "/" ]; do
        if [ -f $x/migraw.yaml ]; then
            echo $x/migraw.yaml
            break;
        fi;
        if [ -f $x/migraw.yml ]; then
            echo $x/migraw.yml
            break;
        fi;
        x=`dirname "$x"`;
    done
}

function parse_yaml() {
    # https://github.com/jasperes/bash-yaml
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
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
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

    sudo apt-get update
    sudo apt-get install unzip p7zip

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
        wget -q -O $DOWNLOAD/php-$PHP_VERSION.zip https://windows.php.net$(curl --silent https://windows.php.net/downloads/releases/latest/ |  grep -zoP '<a href="\K.*?php-'"$PHP_VERSION"'-Win32-VC[0-9][0-9]-x64[^"]+' | tr -d '\0')
    done

    # imagick
    # see https://mlocati.github.io/articles/php-windows-imagick.html
    wget -q -O $DOWNLOAD/imagick-6.9.3.zip http://windows.php.net/downloads/pecl/deps/ImageMagick-6.9.3-7-vc11-x64.zip
    wget -q -O $DOWNLOAD/imagick-7.0.7.zip http://windows.php.net/downloads/pecl/deps/ImageMagick-7.0.7-11-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-5.6.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-5.6-ts-vc11-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.0.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-7.0-ts-vc14-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.1.zip http://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-7.1-ts-vc14-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.2.zip http://windows.php.net/downloads/pecl/snaps/imagick/3.4.3/php_imagick-3.4.3-7.2-ts-vc15-x64.zip
    wget -q -O $DOWNLOAD/php-imagick-7.3.zip http://windows.php.net/downloads/pecl/snaps/imagick/3.4.3/php_imagick-3.4.3-7.3-ts-vc15-x64.zip

    # mailhog
    wget -q -O $BIN/MailHog_windows_amd64.exe https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_windows_amd64.exe

    # mysql
    wget  -q -O $DOWNLOAD/mysql-5.7.zip https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.26-winx64.zip

    # node
    wget  -q -O $DOWNLOAD/node-10.zip https://nodejs.org/dist/v10.15.3/node-v10.15.3-win-x64.zip

    # apc
    wget  -q -O $DOWNLOAD/php-apcu-5.6.zip https://windows.php.net/downloads/pecl/releases/apcu/4.0.11/php_apcu-4.0.11-5.6-ts-vc11-x64.zip
    wget  -q -O $DOWNLOAD/php-apcu-7.0.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.15/php_apcu-5.1.15-7.0-ts-vc14-x64.zip
    wget  -q -O $DOWNLOAD/php-apcu-7.1.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.17/php_apcu-5.1.17-7.1-ts-vc14-x64.zip
    wget  -q -O $DOWNLOAD/php-apcu-7.2.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.17/php_apcu-5.1.17-7.2-ts-vc15-x64.zip
    wget  -q -O $DOWNLOAD/php-apcu-7.3.zip https://windows.php.net/downloads/pecl/releases/apcu/5.1.17/php_apcu-5.1.17-7.3-ts-vc15-x64.zip

    # ruby
    wget  -q -O $DOWNLOAD/ruby-2.5.7z https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-2.5.3-1/rubyinstaller-2.5.3-1-x64.7z

    # apache
    FILENAME=chocolatey-apache-2.4.nupkg
    curl -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" https://chocolatey.org/api/v2/package/apache-httpd -o $DOWNLOAD/$FILENAME
    # somehow it does not work with - d
    # mkdir -p $DOWNLOAD/$(basename ${FILENAME%.*})
    # cp $DOWNLOAD/chocolatey-apache-2.4.nupkg $DOWNLOAD/$(basename ${FILENAME%.*})
    # cd $DOWNLOAD/$(basename ${FILENAME%.*}) && unzip chocolatey-apache-2.4.nupkg
    unzip -uo $DOWNLOAD/$FILENAME -d $DOWNLOAD/$(basename ${FILENAME%.*})
    unzip -uo $(find $DOWNLOAD/chocolatey-apache-2.4 -name "*x64*.zip") -d $DOWNLOAD/$(basename ${FILENAME%.*})
    mv -f $DOWNLOAD/chocolatey-apache-2.4/Apache24 $BIN/apache-2.4
    # rm -rf $DOWNLOAD/$(basename ${FILENAME%.*}) $DOWNLOAD/apache-2.4-tmp

    # cacert
    wget -q -O $BIN/cacert.pem https://curl.haxx.se/ca/cacert.pem

    # composer
    mkdir -p $BIN/composer/
    wget -q -O $BIN/composer/composer.phar https://getcomposer.org/download/1.8.5/composer.phar

    # extract files
    echo "Extracting:"

    for FILENAME in $DOWNLOAD/*.zip
    do
        echo "Extracting" $FILENAME
        unzip -uo $FILENAME -d $BIN/$(basename ${FILENAME%.*})
    done

    # mysql cleanup
    mv $BIN/mysql-5.7/mysql-5.7.26-winx64/* $BIN/mysql-5.7
    rm -rf $BIN/mysql-5.7/mysql-5.7.26-winx64

    # node cleanup
    mv $BIN/node-10/node-v10.15.3-win-x64/* $BIN/node-10
    rm -rf $BIN/node-10/node-v10.15.3-win-x64
    ln -rsf $BIN/node-10/node.exe $BIN/node-10/node
    chmod +x $BIN/node-10/node

    # mysql
    ln -rsf $BIN/mysql-5.7/bin/mysql.exe $BIN/mysql-5.7/bin/mysql

    # extract ruby
    for FILENAME in $DOWNLOAD/*.7z
    do
        echo "Extracting" $FILENAME
        7zr x $FILENAME -o$DOWNLOAD
        mv $DOWNLOAD/rubyinstaller-2.5.3-1-x64 $BIN/ruby-2.5
    done

    # fix ruby symlink
    ln -rsf $BIN/ruby-2.5//bin/ruby.exe $BIN/ruby-2.5//bin/ruby
    chmod +x $BIN/ruby-2.5//bin/ruby

    # copy imagemagik and apc dlls
    for PHP_VERSION in ${AVAILABLE_PHP_VERSIONS[*]}
    do
        cp -rf $(find $BIN/php-imagick-$PHP_VERSION -name "php_*.dll") $BIN/php-$PHP_VERSION/ext
        cp -rf $(find $BIN/php-apcu-$PHP_VERSION -name "php_*.dll") $BIN/php-$PHP_VERSION/ext
    done

    unset PHP_VERSION
}

function set_path {
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/c/Windows/system32"

    PATH=$BIN/apache-2.4/bin:$PATH
    PATH=$BIN/php-$PHP_VERSION:$PATH
    PATH=$BIN/composer:$PATH
    PATH=$BIN/node-10:$PATH
    PATH=$BIN/ruby-2.5/bin:$PATH
    PATH=$BIN/mysql-5.7/bin:$PATH

    if [[ "$PHP_VERSION" == "5.6" || "$PHP_VERSION" == "7.0" || "$PHP_VERSION" == "7.1" ]]; then
        PATH=$BIN/imagick-6.9.3/bin:$PATH
    fi

    if [[ "$PHP_VERSION" == "7.2" || "$PHP_VERSION" == "7.3" ]]; then
        PATH=$BIN/imagick-7.0.7/bin:$PATH
    fi

    PATH=$MIGRAW_CURRENT/gem/bin:$PATH
    PATH=$MIGRAW_CURRENT/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/vendor/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/node_modules/.bin:$PATH

    mkdir -p $MIGRAW_CURRENT/php/session
    create_file_php_ini $MIGRAW_CURRENT/php/php.ini

    PHPRC=$MIGRAW_CURRENT/php
    PHP_INI_SCAN_DIR=$MIGRAW_CURRENT
    MYSQL_HOME=$MIGRAW_CURRENT/mysql

    export PATH
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
        PID=`cat "$MIGRAW_CURRENT/mysql/mysql.pid"`
        cmd.exe /c "taskkill.exe /F /PID $PID > nul" > /dev/null 2>&1
        rm -rf $MIGRAW_CURRENT/mysql/mysql.pid
    fi

    if [ -f $MIGRAW_CURRENT/httpd/httpd.pid ]; then
        PID=`cat $MIGRAW_CURRENT/httpd/httpd.pid`
        cmd.exe /c "taskkill.exe /F /PID $PID > nul" > /dev/null 2>&1
        rm -rf $MIGRAW_CURRENT/httpd/httpd.pid
    fi

    if [ -f $MIGRAW_CURRENT/mailhog/mailhog.pid ]; then
        PID=`cat $MIGRAW_CURRENT/mailhog/mailhog.pid`
        cmd.exe /c "taskkill.exe /F /PID $PID > nul" > /dev/null 2>&1
        rm -rf $MIGRAW_CURRENT/mailhog/mailhog.pid
    fi
}

function spawn_bash {
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

        PATH=$MIGRAW_CURRENT/bin:$BIN/apache-2.4/bin:$BIN/php-$PHP_VERSION:/c/Windows:/c/Windows/System32

        if [[ "$PHP_VERSION" == "5.6" || "$PHP_VERSION" == "7.0" || "$PHP_VERSION" == "7.1" ]]; then
            PATH=\$PATH:$BIN/imagick-6.9.3/bin
        fi

        if [[ "$PHP_VERSION" == "7.2" || "$PHP_VERSION" == "7.3" ]]; then
            PATH=\$PATH:$BIN/imagick-7.0.7/bin
        fi

        WSLENV=PATH/l:PHP_INI_SCAN_DIR/p

        cmd.exe /c \$CMD_FILE_WINDOWS
     #   /bin/rm -rf \$CMD_FILE
EOL

    read -r -d '' PHP_BAT <<EOL
        @echo off
        $BIN_WIN\php-$PHP_VERSION\php.exe -c "$PHPRC\\php.ini" -d "memory_limit=-1" "%*"
        EXIT 0
EOL

    read -r -d '' COMPOSER <<EOL
        php $BIN/composer/composer.phar "\$@"
EOL

    read -r -d '' NPM_BAT <<EOL
        cmd.exe /c "$BIN_WIN\node-10\npm.cmd" "\$@"
EOL

    read -r -d '' GRUNT_BAT <<EOL
        cmd.exe /c "$BIN_WIN\node-10\grunt.cmd" "\$@"
EOL

    read -r -d '' GEM_BAT <<EOL
        cmd.exe /c "$BIN_WIN\ruby-2.5\bin\gem.cmd" "\$@"
EOL

    read -r -d '' BUNDLER_BAT <<EOL
        cmd.exe /c "$BIN_WIN\ruby-2.5\bin\bundler.bat" "\$@"
EOL

    read -r -d '' CAP_BAT <<EOL
        cmd.exe /c "$BIN_WIN\ruby-2.5\bin\cap.bat" "\$@"
EOL

    mkdir -p $MIGRAW_CURRENT/bin

    # solve this as a loop?
    echo "$PHP" > $MIGRAW_CURRENT/bin/php && chmod +x $MIGRAW_CURRENT/bin/php
    echo "$PHP_BAT" > $MIGRAW_CURRENT/bin/php.bat && chmod +x $MIGRAW_CURRENT/bin/php.bat
    echo "$COMPOSER" > $MIGRAW_CURRENT/bin/composer && chmod +x $MIGRAW_CURRENT/bin/composer
    echo "$NPM_BAT" > $MIGRAW_CURRENT/bin/npm && chmod +x $MIGRAW_CURRENT/bin/npm
    echo "$GRUNT_BAT" > $MIGRAW_CURRENT/bin/grunt && chmod +x $MIGRAW_CURRENT/bin/grunt
    echo "$GEM_BAT" > $MIGRAW_CURRENT/bin/gem && chmod +x $MIGRAW_CURRENT/bin/gem
    echo "$BUNDLER_BAT" > $MIGRAW_CURRENT/bin/bundler && chmod +x $MIGRAW_CURRENT/bin/bundler
    echo "$CAP_BAT" > $MIGRAW_CURRENT/bin/cap && chmod +x $MIGRAW_CURRENT/bin/cap

    set_path

    PROMPT="\n${COLOR_PURPLE}\t ${MIGRAW_USER}@${MIGRAW_YAML_name}${COLOR_NC} [${COLOR_RED}\w${COLOR_NC}]${COLOR_NC}\n€${COLOR_NC} "

    if [ "$1" != "" ]; then
        env -i WSLENV=$WSLENV:PHP_INI_SCAN_DIR/p:PHPRC/p:MYSQL_HOME/p PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH HOME=$HOME bash -c "$1"
    else
        env -i WSLENV=$WSLENV:PHP_INI_SCAN_DIR/p:PHPRC/p:MYSQL_HOME/p PHPRC=$PHPRC PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK MYSQL_HOME=$MYSQL_HOME PATH=$PATH HOME=$HOME bash --rcfile <(echo ' PS1="'$(echo $PROMPT)' "')
    fi;
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
    if [ "$MIGRAW_YAML_config_mysql" != "true" ]; then
        return
    fi

    WSLENV=$WSLENV:PATH/l:PHP_INI_SCAN_DIR/p

    BIN_MYSQLD="$BIN/mysql-5.7/bin/mysqld.exe"
    BIN_MYSQL="$BIN/mysql-5.7/bin/mysql.exe"
    chmod +x $BIN_MYSQLD

    MYSQL_BASE_PATH=$MIGRAW_CURRENT/mysql
    MYSQL_BASE_PATH_WINDOWS=$MIGRAW_CURRENT_WINDOWS/mysql

    if [ "$1" == "init" ]; then
        rm -rf $MYSQL_BASE_PATH
        mkdir -p $MYSQL_BASE_PATH/data $MYSQL_BASE_PATH/secure $MYSQL_BASE_PATH/tmp $MYSQL_BASE_PATH/log
        create_file_my_cnf $MYSQL_BASE_PATH/my.cnf
        $BIN_MYSQLD --initialize-insecure --datadir=$MYSQL_BASE_PATH_WINDOWS/data
    fi

    $BIN_MYSQLD \
        --defaults-file="$MYSQL_BASE_PATH_WINDOWS/my.cnf" \
        --log_error="$MYSQL_BASE_PATH_WINDOWS/log/log.err" \
        --pid_file="$MYSQL_BASE_PATH_WINDOWS/mysql.pid" \
        --basedir="$MYSQL_BASE_PATH_WINDOWS" \
        --tmpdir="$MYSQL_BASE_PATH_WINDOWS/tmp" \
        --datadir="$MYSQL_BASE_PATH_WINDOWS/data" &

    counter=1
    while ! $BIN_MYSQL -h127.0.0.1 -uroot -e "show databases;" > /dev/null 2>&1; do
        sleep 1
        counter=`expr $counter + 1`
        if [ $counter -gt 30 ]; then
            echo "We have been waiting for MySQL too long already; failing."
            exit 1
        fi;
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

    # somehow the wslenv part does not work here, so we do the bat trick
    read -r -d "" BIN_HTTPD_CMD <<EOL
        @echo off

        set PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR

        set PATH=$BIN_WIN\\php-$PHP_VERSION;$BIN_WIN\\apache-2.4;%PATH%

        $(
            if [[ "$PHP_VERSION" == "5.6" || "$PHP_VERSION" == "7.0" || "$PHP_VERSION" == "7.1" ]]; then
                IMAGEMAGICK=`wslpath -w $BIN/imagick-6.9.3/bin`
                echo "set PATH=%PATH%;$IMAGEMAGICK;$BIN_WIN\\php-$PHP_VERSION"
            fi
            if [[ "$PHP_VERSION" == "7.2" || "$PHP_VERSION" == "7.3" ]]; then
                IMAGEMAGICK=`wslpath -w $BIN/imagick-7.0.7/bin`
                echo "set PATH=%PATH%;$IMAGEMAGICK;$BIN_WIN\\php-$PHP_VERSION"
            fi
        )

        $(wslpath -w $BIN_HTTPD) \
        -f "$MIGRAW_CURRENT_WINDOWS/httpd/httpd.conf" \
        -c "PidFile $MIGRAW_CURRENT_WINDOWS/httpd/httpd.pid" \
        -c "ServerRoot $BIN_WIN/apache-2.4" \
        -c "ServerName $MIGRAW_YAML_name" \
        -c "ServerAdmin admin@$MIGRAW_YAML_name" \
        -c "Listen $MIGRAW_YAML_network_ip:80" \
        -c "Include $MIGRAW_CURRENT_WINDOWS/httpd/sites/*.conf" \
        -c "ErrorLog $MIGRAW_CURRENT_WINDOWS/httpd/log/error.log" \
        -c "LoadModule php${PHP_VERSION:0:1}_module $BIN_WIN\\php-$PHP_VERSION\\php${PHP_VERSION:0:1}apache2_4.dll" \
        $(
            for DLL_PATH in $BIN/php-$PHP_VERSION/*.dll
            do
                DLL_FILENAME="$(basename $DLL_PATH)"
                if  [[ $DLL_FILENAME == php* ]];
                then
                    continue;
                fi
                DLL_WINDOWS_PATH="$(wslpath -w $DLL_PATH)"
                printf %s " -c \"LoadFile $DLL_WINDOWS_PATH\""
            done
        ) \
        -c "PHPIniDir $MIGRAW_CURRENT_WINDOWS/php/"
EOL

    echo "$BIN_HTTPD_CMD" > $MIGRAW_CURRENT/httpd/exec.bat
    cmd.exe /c `wslpath -w $MIGRAW_CURRENT/httpd/exec.bat` &
}

# see https://stackoverflow.com/a/38275644
function execute_with_progress_spinner {
    if [ "$OPTION" == "debug" ]; then
        $1
    else
        echo -ne "${COLOR_BROWN}Working "
        (while :; do for c in / - \\ \|; do printf '[%s]\b\b\b' "$c"; sleep 0.1; done; done) &
        touch $BASE/migraw.log
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

    if mv "$0.tmp" "$FILE"; then
        echo -e "${COLOR_CYAN}Update complete.${COLOR_NC}\n"
    else
        echo -e "${COLOR_PURPLE}Update failed while moving update file.${COLOR_NC}\n"
    fi
}

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

# download dir
DOWNLOAD=/d/migraw/download
DOWNLOAD_WIN=$($PATH_CONVERT_BIN -w $DOWNLOAD)

# bin base
BIN=/d/migraw/bin
BIN_WIN=$($PATH_CONVERT_BIN -w $BIN)

MIGRAW_YAML=$(find_migraw_yaml)
if [ "$MIGRAW_YAML" != "" ]; then
    eval "$(parse_yaml $MIGRAW_YAML MIGRAW_YAML_)"
    MIGRAW_CURRENT=$(dirname "$MIGRAW_YAML")/.migraw
    MIGRAW_CURRENT_BASE=$(dirname "$MIGRAW_YAML")
else
    MIGRAW_CURRENT=$PWD/.migraw
    MIGRAW_CURRENT_BASE=$PWD
fi

MIGRAW_CURRENT_WINDOWS=$($PATH_CONVERT_BIN -w $MIGRAW_CURRENT)
MIGRAW_CURRENT_BASE_WINDOWS=$($PATH_CONVERT_BIN -w $MIGRAW_CURRENT_BASE)

AVAILABLE_PHP_VERSIONS=("5.6" "7.0" "7.1" "7.2" "7.3")
PHP_VERSION=${AVAILABLE_PHP_VERSIONS[-1]}
PHP_VERSION=$MIGRAW_YAML_config_php

case $ACTION in
    up)
        ;&
    start)
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
    bash)
        spawn_bash "$2"
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
    selfupdate)
        echo -e "\n${COLOR_CYAN}Trying to update migraw.${COLOR_NC}\n"
        self_update
        ;;
    *)
        echo -e "\n${COLOR_CYAN}migraw wsl|cygwin/win64 $VERSION${COLOR_NC}\n"
        echo "[TODO]"
        ;;
esac
