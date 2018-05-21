// TODO: Cleanup the whole class...

using System;
using System.Management;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace Migraw
{
    class Loopback
    {
        public const UInt32 ERROR_CLASS_MISMATCH = 0xE0000203;

        [DllImport("setupapi.dll", SetLastError = true, EntryPoint = "SetupDiOpenDeviceInfo", CharSet = CharSet.Auto)]
        static extern UInt32 SetupDiOpenDeviceInfo(IntPtr DeviceInfoSet, [MarshalAs(UnmanagedType.LPWStr)]string DeviceID, IntPtr Parent, UInt32 Flags, ref SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("setupapi.dll", SetLastError = true, EntryPoint = "SetupDiCreateDeviceInfoList", CharSet = CharSet.Unicode)]
        static extern IntPtr SetupDiCreateDeviceInfoList(IntPtr ClassGuid, IntPtr Parent);

        [DllImport("setupapi.dll", SetLastError = true, EntryPoint = "SetupDiDestroyDeviceInfoList", CharSet = CharSet.Unicode)]
        static extern UInt32 SetupDiDestroyDeviceInfoList(IntPtr DevInfo);

        [DllImport("setupapi.dll", SetLastError = true, EntryPoint = "SetupDiRemoveDevice", CharSet = CharSet.Auto)]
        public static extern int SetupDiRemoveDevice(IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData);

        [StructLayout(LayoutKind.Sequential)]
        public struct SP_DEVINFO_DATA
        {
            public UInt32 Size;
            public Guid ClassGuid;
            public UInt32 DevInst;
            public IntPtr Reserved;
        }

        public static UInt32 GetDeviceInformation(string DeviceID, ref IntPtr DevInfoSet, ref SP_DEVINFO_DATA DevInfo)
        {
            DevInfoSet = SetupDiCreateDeviceInfoList(IntPtr.Zero, IntPtr.Zero);

            if (DevInfoSet == IntPtr.Zero)
            {
                return (UInt32)Marshal.GetLastWin32Error();
            }

            DevInfo.Size = (UInt32)Marshal.SizeOf(DevInfo);

            if (0 == SetupDiOpenDeviceInfo(DevInfoSet, DeviceID, IntPtr.Zero, 0, ref DevInfo))
            {
                SetupDiDestroyDeviceInfoList(DevInfoSet);
                return ERROR_CLASS_MISMATCH;
            }

            return 0;
        }

        public static void ReleaseDeviceInfoSet(IntPtr DevInfoSet)
        {
            SetupDiDestroyDeviceInfoList(DevInfoSet);
        }

        public static UInt32 RemoveDevice(string DeviceID)
        {
            UInt32 ResultCode = 0;
            IntPtr DevInfoSet = IntPtr.Zero;
            SP_DEVINFO_DATA DevInfo = new SP_DEVINFO_DATA();

            ResultCode = GetDeviceInformation(DeviceID, ref DevInfoSet, ref DevInfo);

            if (0 == ResultCode)
            {
                if (1 != SetupDiRemoveDevice(DevInfoSet, ref DevInfo))
                {
                    ResultCode = (UInt32)Marshal.GetLastWin32Error();
                }
                ReleaseDeviceInfoSet(DevInfoSet);
            }

            return ResultCode;
        }


        const int SPDRP_HARDWAREID = 0x00000001;
        const int DICD_GENERATE_ID = 0x00000001;
        const int DIF_REMOVE = 0x00000005;
        const int DIF_REGISTERDEVICE = 0x00000019;
        const int MAX_CLASS_NAME_LEN = 32;
        const int SPDRP_FRIENDLYNAME = 0x0000000C;
        const int SPDRP_ENUMERATOR_NAME = 0x00000016;
        const int DIGCF_DEVICEINTERFACE = 16;
        public const int CR_SUCCESS = 0x00000000;
        public const int CM_LOCATE_DEVNODE_NORMAL = 0x00000000;
        public const int DIGCF_PRESENT = 0x00000002;
        public const int DIGCF_ALLCLASSES = 4;

        [DllImport("setupapi.dll", SetLastError = true)]
        static extern bool SetupDiGetINFClass(string infName, ref Guid ClassGuid, [MarshalAs(UnmanagedType.LPStr)] StringBuilder ClassName, int ClassNameSize, int RequiredSize);

        [DllImport("setupapi.dll", SetLastError = true)]
        static extern IntPtr SetupDiCreateDeviceInfoList(ref Guid ClassGuid, IntPtr hwndParent);

        [DllImport("Setupapi.dll")]
        public static extern bool SetupDiCreateDeviceInfo(IntPtr DeviceInfoSet, String DeviceName, ref Guid ClassGuid, string DeviceDescription, IntPtr hwndParent, Int32 CreationFlags, ref SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("setupapi.dll", SetLastError = true)]
        static extern bool SetupDiSetDeviceRegistryProperty(IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData, uint Property, string PropertyBuffer, int PropertyBufferSize);

        [DllImport("setupapi.dll", SetLastError = true)]
        static extern bool SetupDiCallClassInstaller(UInt32 InstallFunction, IntPtr DeviceInfoSet, ref SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("newdev.dll", SetLastError = true)]
        static extern bool UpdateDriverForPlugAndPlayDevices(IntPtr hwndParent, string HardwareId, string FullInfPath, int InstallFlags, bool bRebootRequired);

        [DllImport("cfgmgr32.dll")]
        public static extern UInt32 CM_Locate_DevNode(ref UInt32 DevInst, string pDeviceID, UInt32 Flags);

        [DllImport("cfgmgr32.dll", SetLastError = true)]
        public static extern UInt32 CM_Reenumerate_DevNode(UInt32 DevInst, UInt32 Flags);
        
        [DllImport("setupapi.dll")]
        public static extern Boolean SetupDiClassGuidsFromNameA(string ClassName, ref Guid Guids, UInt32 ClassNameSize, ref UInt32 RequiredSize);

        [DllImport("setupapi.dll")]
        public static extern IntPtr SetupDiGetClassDevs(ref Guid guid, [MarshalAs(UnmanagedType.LPTStr)] string Enumerator, IntPtr hwndPtr, UInt32 Flags);

        [DllImport("setupapi.dll")]
        public static extern IntPtr SetupDiGetClassDevs(IntPtr guid, [MarshalAs(UnmanagedType.LPTStr)] string Enumerator, IntPtr hwndPtr, UInt32 Flags);

        [DllImport("setupapi.dll")]
        public static extern Boolean SetupDiEnumDeviceInfo(IntPtr DeviceInfoSet, UInt32 DeviceIndex, SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("setupapi.dll", SetLastError = true)]
        public static extern Boolean SetupDiCallClassInstaller(UInt32 InstallFunction, IntPtr DeviceInfoSet, SP_DEVINFO_DATA DeviceInfoData);

        [DllImport("kernel32.dll")]
        static extern uint GetLastError();

        public static bool InstallDriver(string inf, string hwid, string friendName = "")
        {
            StringBuilder className = new StringBuilder(MAX_CLASS_NAME_LEN);
            Guid ClassGUID = new Guid();

            if (!SetupDiGetINFClass(inf, ref ClassGUID, className, MAX_CLASS_NAME_LEN, 0))
                return false;

            IntPtr DeviceInfoSet = SetupDiCreateDeviceInfoList(ref ClassGUID, IntPtr.Zero);
            SP_DEVINFO_DATA DeviceInfoData = new SP_DEVINFO_DATA() { Size = (uint)Marshal.SizeOf(typeof(SP_DEVINFO_DATA)) };

            if (!SetupDiCreateDeviceInfo(DeviceInfoSet, className.ToString(), ref ClassGUID, null, IntPtr.Zero, DICD_GENERATE_ID, ref DeviceInfoData))
                return false;

            if (!SetupDiSetDeviceRegistryProperty(DeviceInfoSet, ref DeviceInfoData, SPDRP_HARDWAREID, hwid, hwid.Length))
            {
                SetupDiDestroyDeviceInfoList(DeviceInfoSet);
                return false;
            }
 
            if (!SetupDiCallClassInstaller(DIF_REGISTERDEVICE, DeviceInfoSet, ref DeviceInfoData))
            {
                SetupDiDestroyDeviceInfoList(DeviceInfoSet);
                return false;
            }

            bool reboot = false;
            if (!UpdateDriverForPlugAndPlayDevices(IntPtr.Zero, hwid, inf, 0, reboot))
            {
                SetupDiCallClassInstaller(DIF_REMOVE, DeviceInfoSet, ref DeviceInfoData);
                return false;
            }

            if (friendName != ""){
                if (!SetupDiSetDeviceRegistryProperty(DeviceInfoSet, ref DeviceInfoData, SPDRP_FRIENDLYNAME, friendName, friendName.Length))
                {
                    Console.WriteLine("Error ");
                }
            }
                 
            Console.WriteLine(DeviceInfoData.ClassGuid);
            Console.WriteLine(DeviceInfoData.DevInst);
            Console.WriteLine(DeviceInfoData.Reserved);

            return true;
        }

        public static void SetupIp(string name, string ip)
        {
            ManagementClass objMC2 = new ManagementClass("Win32_NetworkAdapter");
            ManagementObjectCollection objMOC2 = objMC2.GetInstances();
            foreach (ManagementObject objMO in objMOC2)
            {
 
                foreach (var item in objMO.GetRelated("Win32_PnPEntity"))
                {
                    // Console.WriteLine(item.GetPropertyValue("Name"));
                    // Console.WriteLine(item.GetPropertyValue("PNPDeviceID"));
                    if (item.GetPropertyValue("Name").ToString() == name)
                    {
                        ManagementObjectCollection foo = objMO.GetRelated("Win32_NetworkAdapterConfiguration");

                        foreach (ManagementObject barfoor in foo)
                        {

                            try
                            {
                                ManagementBaseObject objNewIP = null;
                                ManagementBaseObject objSetIP = null;
                                ManagementBaseObject objNewGate = null;
                                ManagementBaseObject objNewDNS = null;

                                objNewIP = barfoor.GetMethodParameters("EnableStatic");
                                objNewGate = barfoor.GetMethodParameters("SetGateways");
                                objNewDNS = barfoor.GetMethodParameters("SetDNSServerSearchOrder");

                                // Set DefaultGateway
                                objNewGate["DefaultIPGateway"] = new string[] { "192.168.64.1" };
                                objNewGate["GatewayCostMetric"] = new int[] { 1 };
                                objNewDNS["DNSServerSearchOrder"] = new string[] { "1.1.1.1", "1.1.0.0" };

                                // Set IPAddress and Subnet Mask
                                objNewIP["IPAddress"] = new string[] { ip };
                                objNewIP["SubnetMask"] = new string[] { "255.255.255.0" };

                                objSetIP = barfoor.InvokeMethod("EnableStatic", objNewIP, null);
                                objSetIP = barfoor.InvokeMethod("SetGateways", objNewGate, null);
                                objSetIP = barfoor.InvokeMethod("SetDNSServerSearchOrder", objNewDNS, null);

                                Console.WriteLine("Updated IPAddress, SubnetMask and Default Gateway!");

                            }
                            catch (Exception ex)
                            {
                                Console.WriteLine("Unable to Set IP : " + ex.Message);
                            }

                            // TODO: Event/Callback when ip is set?
                            Thread.Sleep(10000);

                        }
                    }

                }

            }

        }
    }
}
