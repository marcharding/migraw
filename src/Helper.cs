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

        static public void PrintStdOutErrOut(Process process)
        {
            ProccessStreamPrinter myProcessStream = new ProccessStreamPrinter();
            myProcessStream.Read(ref process);
          
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
