using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

public class ProccessStreamPrinter
{
    private Thread StandardOutputReader;
    private Thread StandardErrorReader;

    private static Process RunProcess;

    public int Read(ref Process process)
    {
        try
        {
            RunProcess = process;

            if (RunProcess.StartInfo.RedirectStandardOutput)
            {
                StandardOutputReader = new Thread(new ThreadStart(ReadStandardOutput));
                StandardOutputReader.Start();
            }

            if (RunProcess.StartInfo.RedirectStandardError)
            {
                StandardErrorReader = new Thread(new ThreadStart(ReadStandardError));
                StandardErrorReader.Start();
            }

            if (StandardOutputReader != null)
                StandardOutputReader.Join();

            if (StandardErrorReader != null)
                StandardErrorReader.Join();

        }
        catch
        { }
        return 1;
    }

    private void ReadStandardOutput()
    {
        if (RunProcess != null)
        {
            using (StreamReader reader = RunProcess.StandardOutput)
            {
                while (!reader.EndOfStream)
                {
                    string line = reader.ReadLine();
                    Console.WriteLine(line);
                }
            }
        }
        Console.Out.Flush();
    }

    private void ReadStandardError()
    {
        if (RunProcess != null)
        {
            using (StreamReader reader = RunProcess.StandardError)
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
        Console.Out.Flush();
    }

}