<#
.SYNOPSIS
This script is used to find intersting files





Function: Find-Files
Author: Watsonox90
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

gdr -PSProvider 'FileSystem' | Where-Object {$_.used -gt 1mb} | foreach {$_.Root} | Get-ChildItem -Force -Recurse| Where-Object {$_.Name -match $FilesAndExt};

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

$files = gdr -PSProvider 'FileSystem' | Where-Object {$_.used -gt 1mb} | foreach {$_.Root} | Get-ChildItem -Force -Recurse| Where-Object {$_.Name -match $FilesAndExt} |  select-object FullName;

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
