function Get-FolderACL 
{
    [CmdletBinding()]
	
    param(
        [Parameter(Mandatory = $true, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String] $Path
		
    )

	$ErrorActionPreference = 'SilentlyContinue'
	
    $PathsToSearch = (Get-ChildItem $Path -recurse|
        Where-Object -FilterScript {
            $_.PSIsContainer 
        } |
    Select-Object -ExpandProperty FullName)

    $weakacllist = @()
    
    foreach($folder in $PathsToSearch)
    {	
        $AccessList = ((Get-Item $folder).GetAccessControl('Access')).Access
        
		foreach($permission in $AccessList)
        {
            if($permission.IdentityReference -like '*domain users*' -or $permission.IdentityReference -like 'everyone')
            {
                $aclObj = New-Object -TypeName System.Object
                $aclObj | Add-Member -MemberType NoteProperty -Name Path -Value $folder
                $aclObj | Add-Member -MemberType NoteProperty -Name GroupAccess -Value $permission.IdentityReference
                $aclObj | Add-Member -MemberType NoteProperty -Name FileSystemRights -Value $permission.FileSystemRights
                $weakacllist += $aclObj

            }
        }
    }

    $weakacllist
}
