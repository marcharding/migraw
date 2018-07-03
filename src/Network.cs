using System.Net;
using System.Net.NetworkInformation;

namespace Migraw
{
    class Network
    {
        public static bool PortInUse(int port)
        {
            IPGlobalProperties ipProperties = IPGlobalProperties.GetIPGlobalProperties();
            IPEndPoint[] ipEndPoints = ipProperties.GetActiveTcpListeners();

            foreach (IPEndPoint ipEndPoint in ipEndPoints)
            {
                if (ipEndPoint.Port == port)
                {
                    return true;
                }
            }

            return false;
        }

    }

}
