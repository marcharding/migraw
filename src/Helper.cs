using Microsoft.Win32;
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Net;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;
using System.DirectoryServices.AccountManagement;

namespace Migraw
{
    class Helper
    {
        public static void DownloadFile(Uri uri, string destination)
        {
            using (var wc = new WebClient())
            {
                wc.Headers.Add("user-agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; .NET CLR 1.0.3705;)");
                wc.DownloadProgressChanged += HandleDownloadProgress;
                wc.DownloadFileCompleted += HandleDownloadComplete;
                // See https://alexfeinberg.wordpress.com/2014/09/14/how-to-use-net-webclient-synchronously-and-still-receive-progress-updates/
                var syncObject = new Object();
                lock (syncObject)
                {
                    wc.DownloadFileAsync(uri, destination, syncObject);
                    // This would block the thread until the download completes
                    Monitor.Wait(syncObject);
                }
            }
            Console.WriteLine();
        }

        public static void HandleDownloadComplete(object sender, AsyncCompletedEventArgs e)
        {
            lock (e.UserState)
            {
                // Releases the blocked thread
                Monitor.Pulse(e.UserState);
            }
        }

        public static void HandleDownloadProgress(object sender, DownloadProgressChangedEventArgs args)
        {
            Console.Write("\rDownloading {0}% ...", args.ProgressPercentage);
        }

        public static string CalculateMD5(string filename)
        {
            using (var md5 = MD5.Create())
            {
                using (var stream = File.OpenRead(filename))
                {
                    var hash = md5.ComputeHash(stream);
                    return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
                }
            }
        }

        // https://gist.github.com/rivy/030df34899e4305ea5837586bf1ff7a4
        static public void PrintStdOutErrOut(Process process)
        {
            using (StreamReader reader = process.StandardOutput)
            {
                while (!reader.EndOfStream)
                {
                    string line = reader.ReadLine();
                    Console.WriteLine(line);
                }
            }
            using (StreamReader reader = process.StandardError)
            {
                while (!reader.EndOfStream)
                {
                    string line = reader.ReadLine();
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine(line);
                    Console.ResetColor();
                }
            }
        }

        // https://gist.github.com/rivy/030df34899e4305ea5837586bf1ff7a4
        // TODO: Look into this further
        public static void PrintCombinedStdOutErrOut(Process process)
        {
            Thread thread = new Thread(() =>
            {
                using (Task<bool> processWaiter = Task.Factory.StartNew(() => process.WaitForExit(-1)))
                using (Task outputReader = Task.Factory.StartNew((Action<object>)AppendLinesFunc, Tuple.Create("stdout", process.StandardOutput)))
                using (Task errorReader = Task.Factory.StartNew((Action<object>)AppendLinesFunc, Tuple.Create("stderr", process.StandardError)))
                {
                    bool waitResult = processWaiter.Result;

                    if (!waitResult)
                    {
                        process.Kill();
                    }

                    Task.WaitAll(outputReader, errorReader);

                    if (!waitResult)
                    {
                        throw new TimeoutException("Process wait timeout expired");
                    }


                }
            })
            {
                IsBackground = true
            };
            thread.Start();
        }
        
        private static void AppendLinesFunc(object packedParams)
        {
            var paramsTuple = (Tuple<string, StreamReader>)packedParams;
            StreamReader reader  = paramsTuple.Item2;
            string marker = paramsTuple.Item1;
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                if (marker == "stderr") { 
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine(line);
                    Console.ResetColor();
                } else {
                    Console.WriteLine(line);
                }
            }
        }

        /// <summary>
        /// Depth-first recursive delete, with handling for descendant 
        /// directories open in Windows Explorer.
        /// </summary>
        /// see https://stackoverflow.com/a/1703799
        public static void DeleteDirectory(string path)
        {
            foreach (string directory in Directory.GetDirectories(path))
            {
                DeleteDirectory(directory);
            }

            try
            {
                Directory.Delete(path, true);
            }
            catch (IOException)
            {
                Directory.Delete(path, true);
            }
            catch (UnauthorizedAccessException)
            {
                Directory.Delete(path, true);
            }
        }

        // https://stackoverflow.com/questions/7189117/find-all-child-processes-of-my-own-net-process-find-out-if-a-given-process-is
        // https://stackoverflow.com/questions/8207994/how-to-wait-on-a-process-and-all-its-child-processes-to-exit/37983587#37983587
        public static void KillAllProcessesSpawnedBy(int parentProcessId)
        {
            ManagementObjectSearcher searcher = new ManagementObjectSearcher(
                "SELECT * " +
                "FROM Win32_Process " +
                "WHERE ParentProcessId=" + parentProcessId);
            ManagementObjectCollection collection = searcher.Get();
            if (collection.Count > 0)
            {
                foreach (var item in collection)
                {
                    int childProcessId = Convert.ToInt32(item["ProcessId"]);
                    if ((int)childProcessId != Process.GetCurrentProcess().Id)
                    {
                        KillAllProcessesSpawnedBy(childProcessId);
                        Process childProcess = Process.GetProcessById((int)childProcessId);
                        childProcess.Kill();
                        childProcess.WaitForExit(-1);
                    }
                }
            }
        }

        // https://superuser.com/questions/1119883/windows-10-enable-ntfs-long-paths-policy-option-missing
        public static void EnableLongPath()
        {
            RegistryKey registryKey;
           
            String[] keys =
             {
                @"SYSTEM\ControlSet001\Control\FileSystem",
                @"SYSTEM\CurrentControlSet\Control\FileSystem",
                @"SYSTEM\CurrentControlSet\Policies",
            };
            
            foreach (String key in keys)
            {
                 registryKey = Registry.LocalMachine.OpenSubKey(key, true);

                if (registryKey != null)
                {
                    registryKey.SetValue("LongPathsEnabled", 1, RegistryValueKind.DWord);
                    registryKey.Close();
                }
                else
                {
                    registryKey = Registry.LocalMachine.CreateSubKey(key, true);
                    registryKey.SetValue("LongPathsEnabled", 1, RegistryValueKind.DWord);
                    registryKey.Close();
                }
            }
           
            String keyUser;
            keyUser = UserPrincipal.Current.Sid + @"\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{B0D05113-7B6B-4D69-81E2-8E8836775C9C}Machine\System\CurrentControlSet\Control\FileSystem";
            registryKey = Registry.Users.OpenSubKey(keyUser, true);

            if (registryKey != null)
            {
                registryKey.SetValue("LongPathsEnabled", 1, RegistryValueKind.DWord);
                registryKey.Close();
            }
            else
            {
                registryKey = Registry.Users.CreateSubKey(keyUser, true);
                registryKey.SetValue("LongPathsEnabled", 1, RegistryValueKind.DWord);
                registryKey.Close();
            }
        }

    }
}
