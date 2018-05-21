using McMaster.Extensions.CommandLineUtils;
using System;

namespace Migraw
{

    class Program
    {

        static void Main(string[] args)
        {
            // enable long paths
            // see https://blogs.msdn.microsoft.com/jeremykuhne/2016/07/30/net-4-6-2-and-long-paths-on-windows-10/
            // https://stackoverflow.com/questions/47473335/runtime-setting-embedded-in-exe

            AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling", false);
            AppContext.SetSwitch("Switch.System.IO.BlockLongPaths", false);

            App app = new App();

            CommandLineApplication cliApp = new CommandLineApplication();

            cliApp.Name = "migraw";

            cliApp.OnExecute(() => {
                if(args.Length == 0)
                {
                    cliApp.ShowHelp();
                }
            });

            cliApp.Command("cmd", (command) =>
            {
                command.Description = "Opens a new cmd window.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    app.Cli();
                });
            });

            cliApp.Command("wsl", (command) =>
            {
                command.Description = "Opens a new wsl window.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    app.WslCli();
                });
            });

            cliApp.Command("exec", (command) =>
            {
                command.Description = "Runs a command inside the cmd enviroment";
                command.HelpOption("-?|-h|--help");
                CommandArgument commandToRun = command.Argument("[command]", "The command to run");
                command.OnExecute(() =>
                {
                    app.Exec(commandToRun.Value);
                });
            });

            cliApp.Command("wsl-exec", (command) =>
            {
                command.Description = "Runs a command inside the wsl enviroment";
                command.HelpOption("-?|-h|--help");
                CommandArgument commandToRun = command.Argument("[command]", "The command to run");
                command.OnExecute(() =>
                {
                    app.Exec(commandToRun.Value);
                });
            });
            
            cliApp.Command("install", (command) =>
            {
                CommandOption force = command.Option("-f|--force", "Force reinstall", CommandOptionType.NoValue);
                command.Description = "Install all binaries.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    app.Install(force.HasValue());
                });
            });

            cliApp.Command("register", (command) =>
            {
                command.Description = "Register migraw to PATH to allow easy global usage.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    var Path = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
                    Environment.SetEnvironmentVariable("PATH", Environment.GetEnvironmentVariable("PATH") + ";" + Path, EnvironmentVariableTarget.User);
                });
            });

            cliApp.Command("destroy", (command) =>
            {
                command.Description = "Destroys the current migraw instance.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    Console.WriteLine("Destroying current migraw instance.");
                    app.Destroy();
                });
            });

            cliApp.Command("up", (command) =>
            {
                command.Description = "Setup & start migraw instance.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    app.Up();
                });
            });

            cliApp.Command("suspend", (command) =>
            {
                command.Description = "Suspend migraw instance (data stays).";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    Console.WriteLine("Suspending current migraw instance.");
                    app.Stop();
                });
            });

            cliApp.Command("resume", (command) =>
            {
                command.Description = "Resume migraw instance.";
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    Console.WriteLine("Resuming current migraw instance.");
                    app.Resume();
                });
            });

            cliApp.Command("remove-loopback", (command) =>
            {
                command.Description = "Remove loopback adapters (alpha)." +
                command.HelpOption("-?|-h|--help");
                command.OnExecute(() =>
                {
                    Loopback.RemoveDevice(@"ROOT\NET\0001");
                    Loopback.RemoveDevice(@"ROOT\NET\0002");
                    Loopback.RemoveDevice(@"ROOT\NET\0003");
                    Loopback.RemoveDevice(@"ROOT\NET\0004");
                    Loopback.RemoveDevice(@"ROOT\NET\0005");
                    Loopback.RemoveDevice(@"ROOT\NET\0006");
                    Loopback.RemoveDevice(@"ROOT\NET\0007");
                    Loopback.RemoveDevice(@"ROOT\NET\0008");
                    Loopback.RemoveDevice(@"ROOT\NET\0009");
                });
            });

            try
            {
                cliApp.Execute(args);
            }
            catch (Exception e)
            {
                ConsoleColor previousColor = Console.ForegroundColor;
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(e.Message);
                Console.ResetColor();
            }
         
        }

    }

}
