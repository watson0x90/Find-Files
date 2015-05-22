<#

# All credit to the original author(s): Ryan Watson (Watson0x90)
#
# Find-Files.ps1 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Find-Files.ps1 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Find-Files.ps1.  If not, see <http://www.gnu.org/licenses/>.

.SYNOPSIS
This script is used to find intersting files

Function: Find-Files
Author: Ryan Watson (Watsonox90)
Required Dependencies: None
Optional Dependencies: None
Version 0.1

.Description
This script is used to find files and file extinsions:
    
    FileExtensions - xls, xlsx, doc, docx, conf
    FileNames - password, creditcard

#>

$ErrorActionPreference = "SilentlyContinue";

$FilesAndExt = '\.doc|\.xls|\.pdf|\.conf$|password|creditcard';

Function Find-Files
{

gdr -PSProvider 'FileSystem' | Where-Object {$_.used -gt 1kb} | foreach {$_.Root} | Get-ChildItem -Force -Recurse| Where-Object {$_.Name -match $FilesAndExt};

}

Function Get-MD5Hash ($file) {
$hasher = [System.Security.Cryptography.MD5]::Create()
$inputStream = New-Object System.IO.StreamReader ($file)
$hashBytes = $hasher.ComputeHash($inputStream.BaseStream)
$inputStream.Close()
$builder = New-Object System.Text.StringBuilder
$hashBytes | Foreach-Object { [void] $builder.Append($_.ToString("X2")) }
$builder.ToString()
}


Function Find-Files-MD5-Evidence
{

$files = gdr -PSProvider 'FileSystem' | Where-Object {$_.used -gt 1kb} | foreach {$_.Root} | Get-ChildItem -Force -Recurse| Where-Object {$_.Name -match $FilesAndExt} |  select-object FullName;

Write-Output "`r`n /* MD5 Hash Values */"

foreach ($_.FullName in $files){
    $pathName = "Path: " + $_.FullName
    Write-Output $pathName
    $md5Value = "MD5: " + $(Get-MD5Hash $_.FullName)
    Write-Output $md5Value
}

}


Function Find-Files-B64
{

$Fetch = gdr -PSProvider 'FileSystem' | Where-Object {$_.used -gt 1kb} | foreach {$_.Root} | Get-ChildItem -Force -Recurse| Where-Object {$_.Name -match $FilesAndExt} | Out-String;

$Prep = [Text.Encoding]::UTF8.GetBytes($Fetch);

$B64Encode = [Convert]::ToBase64String($Prep);

Write-Output $B64Encode;

}
