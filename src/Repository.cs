using System;
using System.Collections.Generic;

namespace Migraw
{
    class Repository
    {
        public static String CaCert  = "https://curl.haxx.se/ca/cacert.pem";

        public static Dictionary<string, string[]> Downloads = new Dictionary<string, string[]> {
            {
                "9f6d787e3a7f035f384c492a6dbd0687",
                new String[] {
                    "https://www.apachelounge.com/download/VC15/binaries/httpd-2.4.33-Win64-VC15.zip",
                    "https://www.apachelounge.com/download/VC15/binaries/httpd-2.4.33-Win64-VC15.zip"
                }
            },
            {
                "ec3e7c4a5d6dd15603ba27613649e88d",
                new String[] {
                    "https://windows.php.net/downloads/releases/archives/php-5.6.34-Win32-VC11-x64.zip"
                }
            },
            {
                "d149cbe3812c58600880a104f9b55e9f",
                new String[] {
                    "https://windows.php.net/downloads/releases/archives/php-7.0.28-Win32-VC14-x64.zip"
                }
            },
            {
                "023dcb3bedf308b21d38f980ac7129b2",
                new String[] {
                    "https://windows.php.net/downloads/releases/archives/php-7.1.15-Win32-VC14-x64.zip"
                }
            },
            {
                    "93946259050ba1901e71fc3621724a92",
                    new String[] {
                    "https://windows.php.net/downloads/releases/archives/php-7.2.3-Win32-VC15-x64.zip"
                }
            },
            {
                "cc99ed2c06981911eaa656f94a58b60d",
                new String[] {
                    "https://windows.php.net/downloads/pecl/deps/ImageMagick-6.9.3-7-vc14-x64.zip"
                }
            },
            
            {
                "6b986c9ba1813ad6af6319c0d2d51620",
                new String[] {
                    "http://windows.php.net/downloads/pecl/deps/ImageMagick-7.0.7-11-vc15-x64.zip"
                }
            },
            
            // https://mlocati.github.io/articles/php-windows-imagick.html
            {
                "3c5c9ed0e428a6e081ff8fa69a4e9309",
                new String[] {
                    "https://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-5.6-ts-vc11-x64.zip"
                }
            },
            {
                "db4b5daed334d0b945febce6c3275dfa",
                new String[] {
                    "https://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-7.0-ts-vc14-x64.zip"
                }
            },
            {
                "cfa18c1a63737ed997011a90e25c10b5",
                new String[] {
                    "https://windows.php.net/downloads/pecl/releases/imagick/3.4.3/php_imagick-3.4.3-7.1-ts-vc14-x64.zip"
                }
            },
            {
                "cbbe4e15dda94b9e3c557701da07a309",
                new String[] {
                    "https://windows.php.net/downloads/pecl/snaps/imagick/3.4.3/php_imagick-3.4.3-7.2-ts-vc15-x64.zip"
                }
            },
            {
                "df5ef385ded7f01bad26aa0dc46fe911",
                new String[] {
                    "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_win_vc14_x86-64.zip"
                }
            },
            {
                "6f96e8e2d58a7963b7ba895b060d8e0f",
                new String[] {
                    "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_win_vc11_x86-64.zip"
                }
            },
            {
                "fe4d1d18766c71e1ee56b1ffa4e87725",
                new String[] {
                    "https://windows.php.net/downloads/pecl/releases/apcu/5.1.11/php_apcu-5.1.11-7.2-ts-vc15-x64.zip"
                }
            },
            {
                "7a631a881a18974448626ae1172ab88d",
                new String[] {
                    "https://windows.php.net/downloads/pecl/releases/apcu/5.1.11/php_apcu-5.1.11-7.1-ts-vc14-x64.zip"
                }
            },
            {
                "b70d168b109982c88c0b274d890ac2ff",
                    new String[] {
                    "https://windows.php.net/downloads/pecl/releases/apcu/5.1.11/php_apcu-5.1.11-7.0-ts-vc14-x64.zip"
                }
            },
            {
                "ffa7c3f37da083c810072935cf6b9cb6",
                new String[] {
                    "https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.21-winx64.zip"
                }
            },
            {
                "a56bb7e6f31181e1804d428155b1b591",
                new String[] {
                    "https://nodejs.org/dist/v8.11.1/node-v8.11.1-win-x64.zip"
                }
            },
            {
                "fae13f93400c58e29f3f3620a90cdfbc",
                new String[] {
                    "https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_windows_amd64.exe"
                }
            },
            {
                "5969d20761e89e8cffb8288c4587f699",
                new String[] {
                    "https://github.com/composer/composer/releases/download/1.6.5/composer.phar"
                }
            }
        };
    }
}

// https://curl.haxx.se/ca/cacert.pem