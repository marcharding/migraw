using Migraw;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using PSHostsFile;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;

namespace Migraw
{

    class App
    {
        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool AllocConsole();

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool FreeConsole();

        [DllImport("kernel32", SetLastError = true)]
        private static extern bool AttachConsole(int dwProcessId);

        String migrawUserDataPath;
        String cwd;
        StringDictionary env = new StringDictionary();
        JObject config;
        NameValueCollection phpVersionToFolder = new NameValueCollection()
        {
            { "5.6", "php-5.6.34-Win32-VC11-x64" },
            { "7.0", "php-7.0.28-Win32-VC14-x64" },
            { "7.1", "php-7.1.15-Win32-VC14-x64" },
            { "7.2", "php-7.2.7-Win32-VC15-x64"  },
        };
        private string phpFolder;

        public App()
        {
            this.SetUpDirs();
            this.migrawUserDataPath = GetMigrawUserFolder();
            this.cwd = Directory.GetCurrentDirectory().ToString();
            if (File.Exists(this.cwd + @"\migraw.json"))
            {
                using (StreamReader reader = File.OpenText(this.cwd + @"\migraw.json"))
                {
                    this.config = (JObject)JToken.ReadFrom(new JsonTextReader(reader));
                }
                this.phpFolder = this.phpVersionToFolder.Get(this.config["config"]["php"].ToString());
                this.SetEnv();
            }
        }

        private void SetUpDotMigrawFolder()
        {
            String[] folders =
            {
                @".migraw\conf",
                @".migraw\conf\apache\vhosts",
                @".migraw\conf\mariadb",
                @".migraw\mariadb\data",
                @".migraw\conf\php",
            };

            foreach (String folder in folders)
            {
                if (!Directory.Exists(folder))
                {
                    Directory.CreateDirectory(folder);
                }
            }

            NameValueCollection embeddedFiles = new NameValueCollection()
            {
                { @".migraw\conf\apache\httpd.conf", Migraw.Properties.Resources.httpd },
                { @".migraw\conf\mariadb\my.ini",Migraw.Properties.Resources.my },
                { @".migraw\conf\php\php.ini", Migraw.Properties.Resources.php }
            };

            foreach (string key in embeddedFiles)
            {
                var value = embeddedFiles[key];
                if (!File.Exists(key))
                {
                    File.WriteAllText(key, value);
                }
            }

            // set extension dir         
            String phpIniFile = @".migraw\conf\php\php.ini";
            String phpIniSettings = $@"extension_dir=../../../../bin/{this.phpFolder}/ext" + "\n";

            // set session save
            phpIniSettings += @".migraw\var\session" + "\n";

            String cacert = $@"curl.cainfo='{GetMigrawUserFolder()}\bin\cacert.pem'";

            switch (this.config["config"]["php"].ToString())
            {
                case "7.0":
                    phpIniSettings += $@"zend_extension={GetMigrawUserFolder()}/bin/ioncube_loaders_win_vc14_x86-64/ioncube/ioncube_loader_win_7.0.dll" + "\n";
                    phpIniSettings += $@"extension=../../../../bin/php_imagick-3.4.3-7.0-ts-vc14-x64/php_imagick.dll" + "\n";
                    phpIniSettings += $@"extension=../../../../bin/php_apcu-5.1.11-7.0-ts-vc14-x64/php_apcu.dll" + "\n";
                    
                    break;
                case "7.1":
                    phpIniSettings += $@"zend_extension={GetMigrawUserFolder()}/bin/ioncube_loaders_win_vc14_x86-64/ioncube/ioncube_loader_win_7.1.dll" + "\n";
                    phpIniSettings += $@"extension=../../../../bin/php_imagick-3.4.3-7.1-ts-vc14-x64/php_imagick.dll" + "\n";
                    phpIniSettings += $@"extension=../../../../bin/php_apcu-5.1.11-7.1-ts-vc14-x64/php_apcu.dll" + "\n";

                    break;
                case "7.2":
                    phpIniSettings += $@"extension={GetMigrawUserFolder()}/bin/php_imagick-3.4.3-7.2-ts-vc15-x64/php_imagick.dll" + "\n";
                    phpIniSettings += $@"extension={GetMigrawUserFolder()}/bin/php_apcu-5.1.11-7.2-ts-vc15-x64/php_apcu.dll" + "\n";
                    break;
                default:
                    Console.WriteLine("No PHP-Version set.");
                    break;
            }

            string phpIniText = File.ReadAllText(phpIniFile);
            phpIniText = phpIniText.Replace("[phpIniSettings]", phpIniSettings);
            phpIniText = phpIniText.Replace("[curl.cainfo]", cacert);
            File.WriteAllText(phpIniFile, phpIniText);

            if (this.config["document_root"] != null && this.config["document_root"].ToString().Length > 0)
            {
                String file = @".migraw\conf\apache\vhosts\normal.conf";
                if (!File.Exists(file))
                {
                    File.WriteAllText(file, Migraw.Properties.Resources.normal);
                    string text = File.ReadAllText(file);
                    text = text.Replace("[REPLACE]", Directory.GetCurrentDirectory().ToString() + @"\" + this.config["document_root"].ToString()).Replace(@"\", "/");
                    File.WriteAllText(file, text);
                }
            }

            if (this.config["virtual_document_root"] != null && this.config["virtual_document_root"].ToString().Length > 0)
            {
                String file = @".migraw\conf\apache\vhosts\wildcard.conf";
                if (!File.Exists(file))
                {
                    File.WriteAllText(file, Migraw.Properties.Resources.wildcard);
                    string text = File.ReadAllText(file);
                    text = text.Replace("[REPLACE]", Directory.GetCurrentDirectory().ToString() + @"\" + this.config["virtual_document_root"].ToString()).Replace(@"\", "/");
                    File.WriteAllText(file, text);
                }
            }
        }

        public StringDictionary SetEnv()
        {
            this.env["PHPRC"] = this.cwd + @"\.migraw\conf\php";
            this.env["MIGRAW_NAME"] = this.config["name"].ToString();
            // see https://www.hanselman.com/blog/ABetterPROMPTForCMDEXEOrCoolPromptEnvironmentVariablesAndANiceTransparentMultiprompt.aspx
            this.env["PROMPT"] = $@"$T$H$H$H$S$C{this.env["MIGRAW_NAME"]}$F$S[$P]$_$$$S";
            this.env["PATH"] = "";
            this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\httpd-2.4.33-Win64-VC15\Apache24\bin";
            this.env["PATH"] += ";" + this.migrawUserDataPath + $@"\bin\{this.phpFolder}";
            this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\node-v8.11.1-win-x64\node-v8.11.1-win-x64";
            this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\composer";
            this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\mysql-5.7.21-winx64\mysql-5.7.21-winx64\bin";
            this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\additional";
            this.env["PATH"] += ";" + $@"{this.cwd}\.migraw\node";
            this.env["NPM_CONFIG_PREFIX"] = $@"{this.cwd}\.migraw\node";

            switch (this.config["config"]["php"].ToString())
            {
                case "7.0":
                    this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\ImageMagick-6.9.3-7-vc14-x64\bin";
                    this.env["DYLD_LIBRARY_PATH"] = this.migrawUserDataPath + @"\bin\ImageMagick-6.9.3-7-vc14-x64\lib";
                    this.env["MAGICK_HOME"] = this.migrawUserDataPath + @"\bin\ImageMagick-6.9.3-7-vc14-x64";
                    break;
                case "7.1":
                    this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\ImageMagick-6.9.3-7-vc14-x64\bin";
                    this.env["DYLD_LIBRARY_PATH"] = this.migrawUserDataPath + @"\bin\ImageMagick-6.9.3-7-vc14-x64\lib";
                    this.env["MAGICK_HOME"] = this.migrawUserDataPath + @"\bin\ImageMagick-6.9.3-7-vc14-x64";
                    break;
                case "7.2":
                    this.env["PATH"] += ";" + this.migrawUserDataPath + @"\bin\ImageMagick-7.0.7-11-vc15-x64\bin";
                    this.env["DYLD_LIBRARY_PATH"] = this.migrawUserDataPath + @"\bin\ImageMagick-7.0.7-11-vc15-x64\lib";
                    this.env["MAGICK_HOME"] = this.migrawUserDataPath + @"\bin\ImageMagick-7.0.7-11-vc15-x64";
                    break;
                default:
                    break;
            }

            this.env["PATH"] += ";";
            return this.env;
        }

        public StringDictionary GetEnv()
        {
            return this.env;
        }

        public void SetUpDirs()
        {
            String[] folders =
            {
                $@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\.migraw",
                $@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\.migraw\bin",
                $@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\.migraw\zip",
            };
            foreach (var folder in folders)
            {
                if (!Directory.Exists(folder))
                {
                    Directory.CreateDirectory(folder);
                }
            }
        }

        public string GetMigrawUserFolder()
        {
            return $@"{Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}\.migraw";
        }
       
        public ProcessStartInfo UpdateEnv(ProcessStartInfo startInfo)
        {
            startInfo.EnvironmentVariables["PATH"] = this.env["PATH"] + startInfo.EnvironmentVariables["PATH"];
            startInfo.EnvironmentVariables["PHPRC"] = this.env["PHPRC"];
            startInfo.EnvironmentVariables["MIGRAW_NAME"] = this.env["MIGRAW_NAME"];
            startInfo.EnvironmentVariables["PROMPT"] = this.env["PROMPT"];
            startInfo.EnvironmentVariables["MAGICK_HOME"] = this.env["MAGICK_HOME"];
            startInfo.EnvironmentVariables["DYLD_LIBRARY_PATH"] = this.env["DYLD_LIBRARY_PATH"];
            startInfo.EnvironmentVariables["LD_LIBRARY_PATH"] = this.env["DYLD_LIBRARY_PATH"];
            // https://docs.npmjs.com/misc/config#environment-variables
            // set local node_modules folder to project root
            startInfo.EnvironmentVariables["NPM_CONFIG_PREFIX"] = $@"{this.cwd}\.migraw\node";
            // see https://github.com/symfony/console/blob/4.0/Output/StreamOutput.php#L94
            // startInfo.EnvironmentVariables["ANSICON"] = "WSL";
            return startInfo;
        }

        public void Up()
        {
            Console.CancelKeyPress += delegate
            {
                Console.WriteLine("Shutdown migraw.");
                Stop();
                Console.ResetColor();
                Console.Out.Flush();
                Environment.Exit(-1);
            };

            if (Directory.Exists(@".migraw"))
            {
                Console.WriteLine(".migraw already exists.");
                Console.WriteLine("Try migraw resume or migraw destroy && migraw up");
                Console.ResetColor();
                Console.Out.Flush();
                Environment.Exit(0);
            }

            Console.WriteLine("Starting migraw setup.");

            this.SetUpDotMigrawFolder();

            if (this.config["network"]["ip"].ToString() != "127.0.0.1")
            {
                Loopback.InstallDriver(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), @"inf\netloop.inf"), "*MSLOOP", this.config["name"].ToString());
                Loopback.SetupIp(this.config["name"].ToString(), this.config["network"]["ip"].ToString());
                // Loopback.RemoveDevice();
            }
              
            try
            {
                HostsFile.Set(this.config["network"]["host"].ToString(), this.config["network"]["ip"].ToString());
            }
            catch (UnauthorizedAccessException)
            {
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("Could not set hosts, please start with admin rights.");
                Console.ResetColor();
            }
            catch (FileNotFoundException)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Could not find hosts file.");
                Console.ResetColor();
            }

            File.WriteAllText(this.cwd + @"\.migraw\apache.pid", ApacheStart());

            if (this.config["config"]["mysql"] != null && this.config["config"]["mysql"].ToString() == true.ToString())
            {
                MysqlSetup();
                File.WriteAllText(this.cwd + @"\.migraw\mysql.pid", MysqlStart());
            }

            if (this.config["config"]["mailhog"] != null && this.config["config"]["mailhog"].ToString() == true.ToString())
            {
                MailhogStart();
            }

            Deps();
        }


        public void Pause()
        {
            Stop();
        }

        public void Resume()
        {
            File.WriteAllText(this.cwd + @"\.migraw\apache.pid", ApacheStart());

            if (this.config["config"]["mysql"] != null && this.config["config"]["mysql"].ToString() == true.ToString())
            {
                File.WriteAllText(this.cwd + @"\.migraw\mysql.pid", MysqlStart());
            }

            if (this.config["config"]["mailhog"] != null && this.config["config"]["mailhog"].ToString() == true.ToString())
            {
                MailhogStart();
            }
        }

        public void Exec(String command)
        {
            // https://stackoverflow.com/questions/35845980/how-can-i-recieve-color-output-from-console-application-like-far?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
            // https://www.codeproject.com/Articles/170017/Solving-Problems-of-Monitoring-Standard-Output-and
            // https://superuser.com/questions/413073/windows-console-with-ansi-colors-handling
            // https://stackoverflow.com/questions/15945016/programmatic-use-of-cmd-exe-from-c-sharp
            // https://docs.microsoft.com/en-us/windows/console/attachconsole
            // https://bobobobo.wordpress.com/2009/03/01/how-to-attach-a-console-to-your-gui-app-in-c/
            Console.ForegroundColor = ConsoleColor.Gray;
            Console.WriteLine("# " + command);
            Console.ForegroundColor = ConsoleColor.White;
            Process process = new Process();
            process.StartInfo.FileName = "cmd.exe";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo = UpdateEnv(process.StartInfo);
            process.StartInfo.Arguments = "/c " + '"' + command + '"';
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.RedirectStandardInput = true;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
            process.Start();
            Helper.PrintStdOutErrOut(process);
            process.WaitForExit();
        }

        public void Cli()
        {
            // see https://superuser.com/questions/413073/windows-console-with-ansi-colors-handling
            // process.StartInfo.Arguments = "/k ansicon.exe";
            Process process = new Process();
            process.StartInfo.FileName = "cmd.exe ";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo = UpdateEnv(process.StartInfo);
            process.StartInfo.Verb = "runas";   
            FreeConsole();
            process.Start();
            return;
        }

        public void WslCli()
        {
            Process process = new Process(); 
            process.StartInfo.FileName = "C:\\Windows\\System32\\bash.exe";
            process.StartInfo.UseShellExecute = false;
            process.StartInfo = UpdateEnv(process.StartInfo);
            FreeConsole();
            process.Start();
            return;
        }

        public void Deps()
        {
            if(this.config["exec"] != null)
            {
                foreach (var dep in this.config["exec"])
                {
                    this.Exec(dep.ToString());
                }
            }
        }

        public void Destroy()
        {
            this.Stop();
            if (!Directory.Exists(@".migraw"))
            {
                Console.WriteLine(".migraw does not exist.");
                Console.ResetColor();
                Console.Out.Flush();
                Environment.Exit(0);
            }
            Helper.DeleteDirectory(@".migraw");
        }

        private bool KillProcessPidFile(string file)
        {
            if (!File.Exists($@"{this.cwd}{file}")){
                return false;
            }
            var pid = Convert.ToInt32(File.ReadAllText($@"{this.cwd}{file}"));
            if (Process.GetProcesses().Any(x => x.Id == pid))
            {
                Process process = Process.GetProcessById(Convert.ToInt32(pid));
                Helper.KillAllProcessesSpawnedBy(Convert.ToInt32(pid));
                process.Kill();
                process.WaitForExit(-1);
                File.Delete($@"{this.cwd}{file}");
                return true;
            }
            return false;
        }

        public void Stop()
        {
            KillProcessPidFile(@"\.migraw\apache.pid");
            KillProcessPidFile(@"\.migraw\mysql.pid");
            KillProcessPidFile(@"\.migraw\mailhog.pid");
        }

        public void Install(bool force)
        {
            Helper.EnableLongPath();
            if (force)
            {
                Directory.Delete(GetMigrawUserFolder(), true);
                SetUpDirs();
                Console.WriteLine("Force reinstall!");
            }

            Console.WriteLine("Downloading and extracing base files, this takes some time.");

            Console.WriteLine("Downloading cacert.pem");

            Helper.DownloadFile(new Uri(Repository.CaCert), $@"{GetMigrawUserFolder()}\bin\cacert.pem");
            
            foreach (KeyValuePair<string, string[]> download in Repository.Downloads)
            {
                foreach (string downloadUrl in download.Value)
                {
                    Uri downloadUri = new Uri(downloadUrl);
                    String file = $@"{GetMigrawUserFolder()}\zip\{Path.GetFileName(downloadUri.ToString())}";

                    if (File.Exists(file) && Helper.CalculateMD5(file) == download.Key)
                    {
                        Console.WriteLine($@"Already downloaded, MD5: {Helper.CalculateMD5(file)}, {file.ToString()}");
                    }
                    else
                    {
                        Console.WriteLine("Starting download of " + Path.GetFileName(downloadUri.ToString()));
                        Helper.DownloadFile(downloadUri, file);
                        if(Helper.CalculateMD5(file) == download.Key)
                        {
                            Console.WriteLine($@"Download OK, MD5: {Helper.CalculateMD5(file)}, {file.ToString()}");
                        } else
                        {
                            Console.WriteLine($@"Checksum ERROR, MD5: {Helper.CalculateMD5(file)}, {file.ToString()}");
                        }
                    }

                    var path = Path.GetFileName(file);

                    if (!Directory.Exists($@"{GetMigrawUserFolder()}\bin\{Path.GetFileNameWithoutExtension(path)}") &&
                        Path.GetExtension(path).ToLower() == ".zip")
                    {
                        System.IO.Compression.ZipFile.ExtractToDirectory(
                            $@"{GetMigrawUserFolder()}\zip\{path}",
                            $@"{GetMigrawUserFolder()}\bin\{Path.GetFileNameWithoutExtension(path)}"
                        );
                    }

                    if (!Directory.Exists($@"{GetMigrawUserFolder()}\bin\{Path.GetFileNameWithoutExtension(path)}") &&
                          Path.GetExtension(path).ToLower() != ".zip")
                    {
                        Directory.CreateDirectory($@"{GetMigrawUserFolder()}\bin\{Path.GetFileNameWithoutExtension(path)}");
                        File.Copy($@"{GetMigrawUserFolder()}\zip\{path}", $@"{GetMigrawUserFolder()}\bin\{Path.GetFileNameWithoutExtension(path)}\{path}");
                    }

                    break;

                }
         
            }
            
            // install helpers
            // TODO: Can these live inside a helper folder?
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-5.6.34-Win32-VC11-x64\php.bat", Migraw.Properties.Resources.php_bat);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-5.6.34-Win32-VC11-x64\php", Migraw.Properties.Resources.php_sh);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-7.0.28-Win32-VC14-x64\php.bat", Migraw.Properties.Resources.php_bat);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-7.0.28-Win32-VC14-x64\php", Migraw.Properties.Resources.php_sh);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-7.1.15-Win32-VC14-x64\php.bat", Migraw.Properties.Resources.php_bat);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-7.1.15-Win32-VC14-x64\php", Migraw.Properties.Resources.php_sh);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-7.2.3-Win32-VC15-x64\php.bat", Migraw.Properties.Resources.php_bat);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\php-7.2.3-Win32-VC15-x64\php", Migraw.Properties.Resources.php_sh);
            File.WriteAllText($@"{GetMigrawUserFolder()}\bin\composer\composer.bat", Migraw.Properties.Resources.composer_bat);
        }

        public string ApacheStart()
        {
            if (Migraw.Network.PortInUse(80))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Port 80 already in use. Unable to start migraw.");
                Console.ResetColor();
                Console.Out.Flush();
                Environment.Exit(0);
            }

            Process process = new Process();
            process.StartInfo.FileName = this.migrawUserDataPath + @"\bin\httpd-2.4.33-Win64-VC15\Apache24\bin\httpd.exe";
            process.StartInfo.Arguments = $@"-f ""{cwd}\.migraw\conf\apache\httpd.conf""";
            process.StartInfo.Arguments += $@" -c ""Include {cwd}/.migraw/conf/apache/vhosts/*.conf""";
            process.StartInfo.Arguments += $@" -c ""PHPIniDir {cwd}/.migraw/conf/php/""";
            if (this.config["config"]["php"].ToString() == "5.6")
            {
                process.StartInfo.Arguments += $@" -c ""LoadModule php5_module '{this.migrawUserDataPath}//bin/{this.phpFolder}/php5apache2_4.dll'""";
            }
            else
            {
                process.StartInfo.Arguments += $@" -c ""LoadModule php7_module '{this.migrawUserDataPath}//bin/{this.phpFolder}/php7apache2_4.dll'""";
            }
            process.StartInfo.Arguments += $@" -c ""Listen {this.config["network"]["ip"].ToString()}:80""";
            process.StartInfo.Arguments += $@" -c ""ServerName {this.config["name"].ToString()}""";
            process.StartInfo.Arguments += $@" -c ""ServerAdmin root@{this.config["name"].ToString()}""";
            process.StartInfo.Arguments += $@" -c ""ErrorLog {cwd}/.migraw/conf/apache/error.log""";
            process.StartInfo.Arguments += $@" -c ""CustomLog {cwd}/.migraw/conf/apache/access.log common""";

            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.RedirectStandardInput = true;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo = UpdateEnv(process.StartInfo);
            process.Start();
            Helper.PrintStdOutErrOut(process);
            return process.Id.ToString();
        }
        
        public string MysqlSetup()
        {
            if (Migraw.Network.PortInUse(3306))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Port 3306 already in use. Unable to start migraw.");
                Console.ResetColor();
                Console.Out.Flush();
                Environment.Exit(0);
            }

            Process process = new Process();
            // mysql_install_db when mariadb
            process.StartInfo.FileName = this.migrawUserDataPath + @"\bin\mysql-5.7.21-winx64\mysql-5.7.21-winx64\bin\mysqld.exe";
            // only when mysql
            process.StartInfo.Arguments += $@" --initialize-insecure";
            process.StartInfo.Arguments += $@" --datadir ""{cwd}/.migraw/mariadb/data""";
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.RedirectStandardInput = true;
            process.Start();
            Helper.PrintStdOutErrOut(process);
            process.WaitForExit(-1);
            return process.Id.ToString();
        }

        public string MysqlStart()
        {
            if (Migraw.Network.PortInUse(3306))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("Port 3306 already in use. Unable to start migraw.");
                Console.ResetColor();
                Console.Out.Flush();
                Environment.Exit(0);
            }

            Process process = new Process();
            // mysql_install_db when mariadb
            process.StartInfo.FileName = this.migrawUserDataPath + @"\bin\mysql-5.7.21-winx64\mysql-5.7.21-winx64\bin\mysqld.exe";
            process.StartInfo.Arguments += $@" --defaults-file=""{cwd}/.migraw/conf/mariadb/my.ini""";
            process.StartInfo.Arguments += $@" --bind-address=""{this.config["network"]["ip"]}""";
            process.StartInfo.Arguments += $@" --datadir=""{cwd}/.migraw/mariadb/data""";
            process.StartInfo.Arguments += $@" --log_error=""{cwd}/.migraw/mariadb/log""";
            process.StartInfo.Arguments += $@" --pid_file=""{cwd}/.migraw/mariadb.pid""";
            process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
            process.StartInfo.CreateNoWindow = false;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.StartInfo.RedirectStandardInput = true;
            process.Start();
            Helper.PrintStdOutErrOut(process);
            return process.Id.ToString();
        }

        public void MailhogStart()
        {
            new Thread(() =>
            {
                Process process = new Process();
                process.StartInfo.FileName = this.migrawUserDataPath + @"\bin\MailHog_windows_amd64\MailHog_windows_amd64.exe";
                process.StartInfo.UseShellExecute = false;
                process.StartInfo.RedirectStandardOutput = true;
                process.StartInfo.RedirectStandardError = true;
                process.StartInfo.RedirectStandardInput = true;
                process.StartInfo.CreateNoWindow = false;
                process.Start();
                Console.WriteLine("Mailhog started.");
                File.WriteAllText(this.cwd + @"\.migraw\mailhog.pid", process.Id.ToString());
                // Helper.PrintStdOutErrOut(process);
                process.WaitForExit(-1);
            })
            {
                IsBackground = true
            }.Start();
        }

    }
}

