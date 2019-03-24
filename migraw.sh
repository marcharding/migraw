#!/usr/bin/env bash

VERSION="0.0.0.1-"$(basename "$0.tmp" | md5sum | cut -d ' ' -f 1 | cut -c1-8);

UPDATE_URL="https://raw.githubusercontent.com/marcharding/migraw/master/migraw.sh";

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

    cp -rf $BIN/php$PHP_VERSION/usr/lib/php/$PHP_VERSION/php.ini-production $1

    sed -i "s|;session.save_path = \"/var/lib/php/sessions\"|session.save_path=$PHPRC/session|g" $1
    sed -i "s|;curl.cainfo =|curl.cainfo=$BIN/cacert.pem|g" $1
    sed -i "s|expose_php = Off|expose_php = ON|g" $1
    sed -i "s|error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT|error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED \& ~E_WARNING|g" $1
    sed -i "s|memory_limit = 128M|memory_limit = 1024M|g" $1
    sed -i "s|display_errors = Off|display_errors = On|g" $1
    sed -i "s|log_errors = On|log_errors = Off|g" $1
    sed -i "s|;realpath_cache_size = 4096k|realpath_cache_size = 4096k|g" $1
    sed -i "s|post_max_size = 8M|post_max_size = 512M|g" $1
    sed -i "s|;opcache.max_accelerated_files=10000|opcache.max_accelerated_files=32768|g" $1

    echo "upload_max_filesize = 512MB" >> $1

    case "$PHP_VERSION" in
        "7.3")
          PHP_EXTENSION_DIR=$BIN/php$PHP_VERSION/usr/lib/php/20180731
        ;;
        "7.2")
          PHP_EXTENSION_DIR=$BIN/php$PHP_VERSION/usr/lib/php/20170718
        ;;
        "7.1")
          PHP_EXTENSION_DIR=$BIN/php$PHP_VERSION/usr/lib/php/20160303
        ;;
        "7.0")
          PHP_EXTENSION_DIR=$BIN/php$PHP_VERSION/usr/lib/php/20151012
        ;;
        "5.6")
          PHP_EXTENSION_DIR=$BIN/php$PHP_VERSION/usr/lib/php/20131226
        ;;
        *)
          PHP_EXTENSION_DIR=$BIN/php$PHP_VERSION/usr/lib/php/20170718
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
extension=json.so
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
zend_extension=xdebug.so
EOL

    LINE=$(grep -n 'extension_dir = "ext"' $1 | cut -d: -f 1)

    head -n $LINE $1 > $1".tmp"
    echo "$EXT" >> $1".tmp"
    tail -n $(($LINE+1)) $1 >> $1".tmp"
    mv $1".tmp" $1
}

function create_file_my_cnf {
    sudo mkdir -p `dirname "$1"`
    sudo cat > $1 << EOL
[mysqld]
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
innodb_use_native_aio          = 0
sync_binlog                    = 0
sql_mode                       = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"
tmp_table_size                 = 64M
innodb_buffer_pool_size        = 512M
innodb_log_file_size           = 128M
innodb_flush_log_at_trx_commit = 2
skip-log-bin
skip-external-locking
EOL
}

function create_file_virtual_host_conf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
<VirtualHost *:*>
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
}

function create_file_httpd_conf {
    mkdir -p `dirname "$1"`
    cat > $1 << EOL
# Timeout: The number of seconds before receives and sends time out.
Timeout 360

# KeepAlive: Whether or not to allow persistent connections (more than
# one request per connection). Set to "Off" to deactivate.
KeepAlive On

# MaxKeepAliveRequests: The maximum number of requests to allow
# during a persistent connection. Set to 0 to allow an unlimited amount.
MaxKeepAliveRequests 512

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

LoadModule access_compat_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_access_compat.so
LoadModule actions_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_actions.so
LoadModule alias_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_alias.so
LoadModule allowmethods_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_allowmethods.so
LoadModule asis_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_asis.so
LoadModule auth_basic_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_auth_basic.so
LoadModule authn_core_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_authn_core.so
LoadModule authn_file_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_authn_file.so
LoadModule authz_core_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_authz_core.so
LoadModule authz_groupfile_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_authz_groupfile.so
LoadModule authz_host_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_authz_host.so
LoadModule authz_user_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_authz_user.so
LoadModule autoindex_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_autoindex.so
LoadModule cgi_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_cgi.so
LoadModule dir_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_dir.so
LoadModule env_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_env.so
LoadModule include_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_include.so
LoadModule mpm_prefork_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_mpm_prefork.so
LoadModule mime_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_mime.so
LoadModule negotiation_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_negotiation.so
LoadModule rewrite_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_rewrite.so
LoadModule setenvif_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_setenvif.so
LoadModule vhost_alias_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_vhost_alias.so
LoadModule headers_module $BIN/apache2-bin/usr/lib/apache2/modules/mod_headers.so

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

function find_migraw_yaml {
    x=`pwd`;
    while [ "$x" != "/" ]; do
        if [ -f $x/migraw.yaml ]; then
            echo $x/migraw.yaml
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

    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt-get update

    sudo rm -rf $DOWNLOAD
    sudo rm -rf $BIN

    sudo mkdir -p $DOWNLOAD
    sudo mkdir -p $BIN
    sudo chmod -R 777 $BASE

    cd $DOWNLOAD

    # Deps
    apt-get download unzip libapr1 libaprutil1 libaio1 \
    libhttp-parser2.7.1 libuv1 libc-ares2 `#node` \
    libzip4 `#zip` \
    libgd3 libxpm4 libfontconfig1 libjpeg8 libjpeg-turbo8 libgif7 libpng16-16 libjpeg62 libtiff5 libwebp6 libjbig0 `#gd` \
    libmagickcore-6.q16-3 libc6 libmagickwand-6.q16-3 libgomp1-amd64-cross liblcms2-2 liblqr-1-0 `#php-imagick `\
    libbz2-1.0 libc6 libfftw3-double3 libfreetype6 libgcc1 liblcms2-2 liblqr-1-0 libltdl7 liblzma5 libx11-6 libxext6 libxml2 zlib1g \
    libpcre2-16-0 libpcre2-32-0 libpcre2-8-0

    # MySQL
    apt-get download mysql-common mysql-server-core-5.7 mysql-server-5.7 mysql-client-5.7 mysql-client-core-5.7

    # Apache
    apt-get download apache2 apache2-bin

    # PHP 7.2
    apt-get download php-xdebug php-imagick php-libsodium libsodium23

    AVAILABLE_PHP_VESIONS=("5.6" "7.0" "7.1" "7.2" "7.3")

    for CURRENT_PHP_VERSION in ${AVAILABLE_PHP_VESIONS[*]}
    do
        apt-get download \
        libapache2-mod-php$CURRENT_PHP_VERSION \
        php$CURRENT_PHP_VERSION-bcmath \
        php$CURRENT_PHP_VERSION-cli \
        php$CURRENT_PHP_VERSION-common \
        php$CURRENT_PHP_VERSION-curl \
        php$CURRENT_PHP_VERSION-gd \
        php$CURRENT_PHP_VERSION-gd \
        php$CURRENT_PHP_VERSION-intl \
        php$CURRENT_PHP_VERSION-json \
        php$CURRENT_PHP_VERSION-mbstring \
        php$CURRENT_PHP_VERSION-mysql \
        php$CURRENT_PHP_VERSION-mysql \
        php$CURRENT_PHP_VERSION-opcache \
        php$CURRENT_PHP_VERSION-phpdbg \
        php$CURRENT_PHP_VERSION-readline \
        php$CURRENT_PHP_VERSION-soap \
        php$CURRENT_PHP_VERSION-soap \
        php$CURRENT_PHP_VERSION-sqlite3 \
        php$CURRENT_PHP_VERSION-xml \
        php$CURRENT_PHP_VERSION-xsl \
        php$CURRENT_PHP_VERSION-xsl \
        php$CURRENT_PHP_VERSION-zip
    done

    # node
    curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
    apt-get download nodejs


    # ruby
    apt-get download ruby2.5 libruby2.5

    # mailhog
    wget -q -O $BIN/MailHog_linux_amd64 https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64
    chmod +x $BIN/MailHog_linux_amd64

    cd $BASE

    # extract files
    echo "Extracting:"

    for filename in $DOWNLOAD/*.dupdateeb
    do
        FILENAME=$(dpkg -f $filename Package)
        echo "Extracting" $filename
        mkdir -p "$BIN/$FILENAME"
        dpkg -x $filename "$BIN/$FILENAME"
    done

    # flatten php

    for AVAILABLE_PHP_VESION in ${AVAILABLE_PHP_VESIONS[*]}
    do
      cd $BIN
      rm -rf $BIN/php$AVAILABLE_PHP_VESION
      PHP_FOLDERS=$(ls -d -1 php$AVAILABLE_PHP_VESION*);
      mkdir -p $BIN/php$AVAILABLE_PHP_VESION
      for folder in $PHP_FOLDERS
      do
          cp -RT $folder/ php$AVAILABLE_PHP_VESION/
      done
      cp -RT php-imagick/ php$AVAILABLE_PHP_VESION/
      cp -RT php-xdebug/ php$AVAILABLE_PHP_VESION
      # add php symlink
      ln -rsf $BIN/php$AVAILABLE_PHP_VESION/usr/bin/php$AVAILABLE_PHP_VESION $BIN/php$AVAILABLE_PHP_VESION/usr/bin/php
    done

    # mime types
    mkdir -p $BIN/apache2/etc/apache2/conf
    wget -q -O $BIN/apache2/etc/apache2/conf/mime.types http://svn.apache.org/viewvc/httpd/httpd/branches/2.4.x/docs/conf/mime.types?revision=1810122&view=co

    # cacert
    wget -q -O $BIN/cacert.pem https://curl.haxx.se/ca/cacert.pem;

    # fix ruby
    ln -rsf $BIN/ruby2.5/usr/bin/erb2.5 $BIN/ruby2.5/usr/bin/erb
    ln -rsf $BIN/ruby2.5/usr/bin/gem2.5 $BIN/ruby2.5/usr/bin/gem
    ln -rsf $BIN/ruby2.5/usr/bin/irb2.5 $BIN/ruby2.5/usr/bin/irb
    ln -rsf $BIN/ruby2.5/usr/bin/rdoc2.5 $BIN/ruby2.5/usr/bin/rdoc
    ln -rsf $BIN/ruby2.5/usr/bin/ri2.5 $BIN/ruby2.5/usr/bin/ri
    ln -rsf $BIN/ruby2.5/usr/bin/ruby2.5 $BIN/ruby2.5/usr/bin/ruby

    # is this really needed?
    mkdir -p $BIN/libruby2.5/usr/bin/
    ln -rsf $BIN/ruby2.5/usr/bin/ruby2.5 $BIN/libruby2.5/usr/bin/ruby2.5
    sed -i "s|/usr/bin/ruby2.5|$BIN/ruby2.5/usr/bin/ruby|g" $BIN/ruby2.5/usr/bin/*

    # composer
    PHP_VERSION=7.2 set_path
    mkdir -p $BIN/php/usr/bin
    $BIN/php7.2/usr/bin/php7.2 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    $BIN/php7.2/usr/bin/php7.2 composer-setup.php --install-dir=$BIN/php/usr/bin/ --filename=composer
    $BIN/php7.2/usr/bin/php7.2 -r "unlink('composer-setup.php');"

    # update npm
    NPM_CONFIG_PREFIX=$BIN/nodejs
    $BIN/nodejs/usr/bin/npm install npm -g
}

function set_path {
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    PHP_INI_SCAN_DIR=$MIGRAW_CURRENT/.migraw-custom
    PATH=$BIN/unzip/usr/bin:$PATH
    PATH=$BIN/mysql-client-core-5.7/usr/bin:$PATH
    PATH=$BIN/mysql-client-5.7/usr/bin:$PATH
    PATH=$BIN/php$PHP_VERSION/usr/bin:$PATH
    PATH=$BIN/php/usr/bin:$PATH
    PATH=$BIN/nodejs/usr/bin:$PATH
    PATH=$BIN/nodejs/bin:$PATH
    PATH=$BIN/libruby2.5/usr/bin:$PATH
    PATH=$BIN/ruby2.5/usr/bin:$PATH

    PATH=$MIGRAW_CURRENT/gem/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/vendor/bin:$PATH
    PATH=$MIGRAW_CURRENT_BASE/node_modules/.bin:$PATH

    DYLD_LIBRARY_PATH=$BIN/libc-ares2/usr/lib/x86_64-linux-gnu
    DYLD_LIBRARY_PATH=$BIN/libuv1/usr/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libaio1/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libsodium23/usr/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libapr1/usr/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libaprutil1/usr/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libhttp-parser2.7.1/usr/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libzip4/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libgd3/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libxpm4/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libfontconfig1/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libjpeg-turbo8/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libgif7/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libpng16-16/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libtiff5/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libwebp6/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libjbig0/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libruby2.5/usr/lib/x86_64-linux-gnu:$DYLD_LIBRARY_PATH

    DYLD_LIBRARY_PATH=$BIN/libpcre2-8-0/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libpcre2-16-0/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libpcre2-32-0/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH

    # Ruby
    GEM_HOME=$MIGRAW_CURRENT/gem
    GEM_SPEC_CACHE=$MIGRAW_CURRENT/gem/spec
    GEM_PATH=$BIN/libruby2.5/usr/lib/ruby/2.5.0:$GEM_HOME
    RUBYLIB=$BIN/libruby2.5/usr/lib/ruby/2.5.0:$BIN/libruby2.5/usr/lib/x86_64-linux-gnu/ruby/2.5.0

    # Imagemagick
    DYLD_LIBRARY_PATH=$BIN/libc6/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libmagickcore-6.q16-3/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libmagickwand-6.q16-3/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/liblcms2-2/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/liblqr-1-0/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libgomp1-amd64-cross/usr/x86_64-linux-gnu/lib/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libbz2-1.0/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libfftw3-double3/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libfreetype6/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libgcc1/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libltdl7/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/liblzma5/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libx11-6/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libxext6/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/libxml2/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    DYLD_LIBRARY_PATH=$BIN/zlib1g/usr/lib/x86_64-linux-gnu/:$DYLD_LIBRARY_PATH
    MAGICK_CODER_MODULE_PATH=$BIN/libmagickcore-6.q16-3/usr/lib/x86_64-linux-gnu/ImageMagick-6.9.7/modules-Q16/coders
    LD_LIBRARY_PATH=$DYLD_LIBRARY_PATH

    # remove duplicate entries
    PATH=$(echo -n $PATH | awk -v RS=: -v ORS=: '{ if (!arr[$0]++) { print $0 } }')
    DYLD_LIBRARY_PATH=$(echo -n $DYLD_LIBRARY_PATH | awk -v RS=: -v ORS=: '{ if (!arr[$0]++) { print $0 } }')
    LD_LIBRARY_PATH=$(echo -n $LD_LIBRARY_PATH | awk -v RS=: -v ORS=: '{ if (!arr[$0]++) { print $0 } }')

    # PHP
    PHPRC=$MIGRAW_CURRENT/php
    mkdir -p $MIGRAW_CURRENT/php/session
    create_file_php_ini $MIGRAW_CURRENT/php/php.ini

    NODE_PATH=$MIGRAW_CURRENT/node
    NPM_CONFIG_PREFIX=$MIGRAW_CURRENT/npm
    NPM_CONFIG_CACHE=$MIGRAW_CURRENT/npm/npm-cache
    NPM_CONFIG_USERCONFIG=$MIGRAW_CURRENT/npm

    # https://docs.npmjs.com/misc/config

    export PATH
    export DYLD_LIBRARY_PATH
    export LD_LIBRARY_PATH
    export PHPRC
    export MAGICK_HOME
    export MAGICK_CODER_MODULE_PATH
    export PHP_INI_SCAN_DIR
    export NPM_CONFIG_PREFIX
    export NPM_CONFIG_CACHE
    export NPM_CONFIG_USERCONFIG
    export NODE_PATH


    # https://www.tutorialspoint.com/ruby/ruby_environment_variables.htm
    # https://guides.rubygems.org/command-reference/#gem-environment
    export GEM_PATH
    export GEM_SPEC_CACHE
    export GEM_SPEC
    export RUBYLIB
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
        sudo kill -9 `sudo cat "$MIGRAW_CURRENT/mysql/mysql.pid"`
        sudo rm -rf $MIGRAW_CURRENT/mysql/mysql.pid
    fi

    if [ -f $MIGRAW_CURRENT/httpd/httpd.pid ]; then
        PID=`sudo cat $MIGRAW_CURRENT/httpd/httpd.pid`
        for CHILD_PID in `pgrep -P $PID`
        do
            sudo kill -9 $CHILD_PID
        done
        sudo kill -9 $PID
        sudo rm -rf $MIGRAW_CURRENT/httpd/httpd.pid
    fi

    if [ -f $MIGRAW_CURRENT/mailhog/mailhog.pid ]; then
        sudo kill -9 `sudo cat "$MIGRAW_CURRENT/mailhog/mailhog.pid"`
        sudo rm -rf $MIGRAW_CURRENT/mailhog/mailhog.pid
    fi
}

function spawn_bash {
    set_path

    PROMPT="\n${COLOR_PURPLE}\t ${MIGRAW_USER}@${MIGRAW_YAML_name}${COLOR_NC} [${COLOR_RED}\w${COLOR_NC}]${COLOR_NC}\n€${COLOR_NC} "

    if [ "$1" != "" ]; then
        env -i NPM_CONFIG_USERCONFIG=$NPM_CONFIG_USERCONFIG NPM_CONFIG_CACHE=$NPM_CONFIG_CACHE GEM_SPEC_CACHE=$GEM_SPEC_CACHE NODE_PATH=$NODE_PATH NPM_CONFIG_PREFIX=$NPM_CONFIG_PREFIX PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK RUBYLIB=$RUBYLIB GEM_PATH=$GEM_PATH GEM_HOME=$GEM_HOME PATH=$PATH DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH PHPRC=$PHPRC HOME=$HOME bash --rcfile <(echo 'PS1="'"$MIGRAW_USER@$MIGRAW_YAML_name"':\w\$ "') -c "$1"
    else
        env -i NPM_CONFIG_USERCONFIG=$NPM_CONFIG_USERCONFIG NPM_CONFIG_CACHE=$NPM_CONFIG_CACHE GEM_SPEC_CACHE=$GEM_SPEC_CACHE NODE_PATH=$NODE_PATH NPM_CONFIG_PREFIX=$NPM_CONFIG_PREFIX PHP_INI_SCAN_DIR=$PHP_INI_SCAN_DIR TERM=$TERM SSH_AUTH_SOCK=$SSH_AUTH_SOCK RUBYLIB=$RUBYLIB GEM_PATH=$GEM_PATH GEM_HOME=$GEM_HOME PATH=$PATH DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH PHPRC=$PHPRC HOME=$HOME bash --rcfile <(echo 'PS1="'$(echo $PROMPT)' "')
    fi;
}

function mailhog_start {
    if [ "$MIGRAW_YAML_config_mailhog" != "true" ]; then
        return
    fi

    mkdir -p $MIGRAW_CURRENT/mailhog/log
    $BIN/MailHog_linux_amd64 > $MIGRAW_CURRENT/mailhog/log/mailhog.log 2>&1 & echo "$!" > $MIGRAW_CURRENT/mailhog/mailhog.pid
}

function mysql_start {
    if [ "$MIGRAW_YAML_config_mysql" != "true" ]; then
      return
    fi

    set_path

    BIN_MYSQLD="$BIN/mysql-server-core-5.7/usr/sbin/mysqld"

    mkdir -p $MIGRAW_CURRENT/mysql/log

    # for wsl mysql stuff must be inside the wsl filesystem
    MYSQL_BASE_PATH=/opt/migraw/$MIGRAW_CURRENT_HASH/mysql

    if [ "$1" == "init" ]; then
        sudo rm -rf $MYSQL_BASE_PATH

        sudo mkdir -p $MYSQL_BASE_PATH/data $MYSQL_BASE_PATH/secure $MYSQL_BASE_PATH/tmp
        sudo chmod -R 777 $MYSQL_BASE_PATH
        create_file_my_cnf $MYSQL_BASE_PATH/my.cnf
        sudo chmod 777 $MYSQL_BASE_PATH
        sudo chmod 655 $MYSQL_BASE_PATH/my.cnf

        sudo PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH -E $BIN_MYSQLD --user=root --initialize-insecure --innodb_use_native_aio=0 --lc-messages-dir="$BIN/mysql-server-core-5.7/usr/share/mysql" --datadir=$MYSQL_BASE_PATH/data > $MIGRAW_CURRENT/mysql/log/init.log 2>&1
    fi

    sudo PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH -E $BIN_MYSQLD \
        --defaults-file="$MYSQL_BASE_PATH/my.cnf" \
        --lc-messages-dir="$BIN/mysql-server-core-5.7/usr/share/mysql" \
        --log_error="$MIGRAW_CURRENT/mysql/log/log.err" \
        --pid_file="$MIGRAW_CURRENT/mysql/mysql.pid" \
        --basedir="$MYSQL_BASE_PATH" \
        --secure_file_priv="$MYSQL_BASE_PATH/secure" \
        --tmpdir="$MYSQL_BASE_PATH/tmp" \
        --datadir="$MYSQL_BASE_PATH/data" \
        --socket="$MYSQL_BASE_PATH/mysql.sock" \
        --user="root" &
}

function apache_start {

    if [ "$MIGRAW_YAML_config_apache" != "true" ]; then
      return
    fi

    set_path

    BIN_HTTPD="$BIN/apache2-bin/usr/sbin/apache2"

    mkdir -p $MIGRAW_CURRENT/httpd $MIGRAW_CURRENT/httpd/log $MIGRAW_CURRENT/httpd/sites

    create_file_httpd_conf $MIGRAW_CURRENT/httpd/httpd.conf
    create_file_virtual_host_conf $MIGRAW_CURRENT/httpd/sites/default.conf

    sudo PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH -E $BIN_HTTPD \
        -f "$MIGRAW_CURRENT/httpd/httpd.conf" \
        -c "PidFile $MIGRAW_CURRENT/httpd/httpd.pid" \
        -c "ServerRoot $BIN/apache2/etc/apache2" \
        -c "ServerName $MIGRAW_YAML_name" \
        -c "ServerAdmin admin@$MIGRAW_YAML_name" \
        -c "Listen $MIGRAW_YAML_network_ip:80" \
        -c "Include $MIGRAW_CURRENT/httpd/sites/*.conf" \
        -c "CustomLog  $MIGRAW_CURRENT/httpd/log/access.log common" \
        -c "ErrorLog $MIGRAW_CURRENT/httpd/log/error.log" \
        -c "LoadModule php${PHP_VERSION:0:1}_module $BIN/libapache2-mod-php$PHP_VERSION/usr/lib/apache2/modules/libphp$PHP_VERSION.so" \
        -c "PHPIniDir $MIGRAW_CURRENT/php/" &
}

# see https://stackoverflow.com/a/38275644
function execute_with_progress_spinner {
    if [ "$OPTION" == "debug" ]; then
        $1
    else
        echo -ne "${COLOR_BROWN}Working "
        (while :; do for c in / - \\ \|; do printf '[%s]\b\b\b' "$c"; sleep 0.1; done; done) &
        sudo touch $BASE/migraw.log
        sudo chmod 777 $BASE/migraw.log
        SPINNER=$!
        {
            $1 > $BASE/migraw.log 2>&1
        }
        { echo -e "${COLOR_NC}\r${COLOR_PURPLE}Finished.   "; kill $SPINNER && wait $SPINNER; } 2>/dev/null
    fi
}

# adapted from https://stackoverflow.com/q/8595751
function self_update {
    FILE=$(readlink -f "$0")

    if ! sudo wget --quiet --output-document="$0.tmp" $UPDATE_URL ; then
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
    if ! sudo chmod $OCTAL_MODE "$0.tmp" ; then
        echo -e "${COLOR_PURPLE}Error while trying to set mode on update file.${COLOR_NC}\n"
        exit 1
    fi

    if sudo mv "$0.tmp" "$FILE"; then
        echo -e "${COLOR_CYAN}Update complete.${COLOR_NC}\n"
    else
        echo -e "${COLOR_PURPLE}Update failed while moving update file.${COLOR_NC}\n"
    fi
}

ACTION=$1

OPTION="${2//-}"

# base dir
BASE="$( cd "$(dirname "$0")" ; pwd -P )"

# migraw user
if [ "$SUDO_USER" != "" ]; then
    MIGRAW_USER=$SUDO_USER
else
    MIGRAW_USER=$USER
fi

# download dir
DOWNLOAD=$BASE/download

# bin base
BIN=$BASE/bin

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

PHP_VERSION="7.2"
PHP_VERSION=$MIGRAW_YAML_config_php

MIGRAW_CURRENT_HASH=$(echo $MIGRAW_CURRENT | md5sum | cut -d" " -f1)
MIGRAW_CURRENT_HASH=${MIGRAW_YAML_name}_${MIGRAW_CURRENT_HASH:0:8}

case $ACTION in
    up)
        ;&
    start)
        echo -e "\n${COLOR_CYAN}Starting migraw${COLOR_NC}\n"
        sudo -v
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
        sudo -v
        execute_with_progress_spinner "stop"
        clean
        ;;
    suspend)
        ;&
    pause)
        echo -e "\n${COLOR_CYAN}Pause migraw.${COLOR_NC}\n"
        sudo -v
        execute_with_progress_spinner "stop"
        ;;
    resume)
        ;&
    unpause)
        echo -e "\n${COLOR_CYAN}Unpause migraw.${COLOR_NC}\n"
        sudo -v
        execute_with_progress_spinner "unpause"
        ;;
    bash)
        spawn_bash "$2"
        ;;
    update)
        ;&
    install)
        echo -e "\n${COLOR_CYAN}Installing needed binaries and libaries.${COLOR_NC}\n"
        sudo -v
        execute_with_progress_spinner "install"
        ;;
    status)
        echo -e "\n${COLOR_CYAN}Current status [TODO].${COLOR_NC}\n"
        ;;
    selfupdate)
        echo -e "\n${COLOR_CYAN}Trying to update migraw.${COLOR_NC}\n"
        sudo -v
        self_update
        ;;
    *)
        echo -e "\n${COLOR_CYAN}migraw wsl/ubuntu $VERSION${COLOR_NC}\n"
        echo "[TODO]"
        ;;
esac
