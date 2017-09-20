function Find-CCData
{
    <#
            If statements to read file extensions and then act accordingly. This was initially designed to scan
	    an entire host looking for potential locations where credit card data might be stored. Programs will 
	    write temporary files within their own program directory or even temp directories. 
	    
	    Author: Ryan Watson
	    Additional credit goes to: @harmj0y, @darkoperator, the PowerShell Mafia and likely people on stack overflow. 
            		
            Requires Office to be installed to scan Word Documents and Excel Documents.
            For excel an additaionl driver needs to be installed depending on version of office installed
            on the scanning host.
        
            Requirements: 
            *) For Office 2010: http://www.microsoft.com/en-us/download/confirmation.aspx?id=13255
            *) For Office 2007: https://www.microsoft.com/en-us/download/confirmation.aspx?id=23734
        
            Also depending on the office version installed, you might need ot run powershell from:
            C:\Windows\SysWOW64\WindowsPowershell\v1.0\powershell.exe
        
	    To generate test credit card data, use the following site: http://www.getcreditcardnumbers.com/

            CC RegEx
            '\b(?:4[0-9]{12}(?:[0-9]{3})?       # Visa
            |  5[1-5][0-9]{14}                  # MasterCard
            |  3[47][0-9]{13}                   # American Express
            |  3(?:0[0-5]|[68][0-9])[0-9]{11}   # Diners Club
            |  6(?:011|5[0-9]{2})[0-9]{12}      # Discover
            |  (?:2131|1800|35\d{3})\d{11}      # JCB
            )\b'

            TODO:   1) If we are able to scan a file with a specific extension add that 
            to a temporay list so that there isnt a need to retest if that
            file extension can be read
            2) Attempt to gather statistics of files that are readable by extension
            then report by extension initiall to test files for CC Data
            "Get-Childitem c:\local -Recurse | where { -not $_.PSIsContainer } | group Extension -NoElement | sort count -desc"

    #>
    [CmdletBinding()]
		
    param(
        [Parameter(Mandatory = $true, position = 0)]
        [ValidateNotNullOrEmpty()]
        [String] $pts,
		
        [Parameter(Mandatory = $true, position = 1)]
        [ValidateNotNullOrEmpty()]
        [String] $out,
		
	[Parameter(Mandatory = $false, position = 2)]
        [ValidateNotNullOrEmpty()]
        [Switch] $office = $false,
		
        $ErrorActionPreference = 'SilentlyContinue',
        
        [String] $global:badPath = '\\Windows\\Microsoft\.NET|\\Windows\\Help|\\Windows\\assembly|\\Windows\\Installer|\\Windows\\PolicyDefinitions|\\Windows\\SoftwareDistribution|\\Windows\\System32|\\Windows\\SysWOW64|\\Windows\\twain_32|\\Windows\\Security|\\Windows\\Media|\\Windows\\SystemResources|\\Windows\\Fonts|\\Windows\\System|\\Windows\\Tasks|\\Windows\\TAPI|\\Windows\\WinStore|\\Windows\\Setup|\\Windows\\WinSxs|\\Windows\\System32|\\Windows\\ADFS|\\Program\sFiles',
        [String] $global:FileExts = '\.dat$|\.bat$|\.cm_err$|\.cm_don$|\.snp$|\.err$|\.don$|\.p1$|\.wfs$|\.hdr$|\.pkt$|\.tif$|\.det$|\.ai$|\.asp$|\.vbs$|\.lnk$|\.thumb$|\.db$|\.swf$|\.hxn$|\.sql$|\.[a-z]{2}_$|\.diagpkg$|\.xsd$|\.aux$|\.ps1$|\.acl$|\.settingcontent-ms$|\.winmd$|\.recovery$|\.msi$|\.pckgdep$|\.pcap$|\.pyc$|\.vb$|\.properties$|\.cfs$|\.key$|\.ht$|\.dtd$|\.ui$|\.ott$|\.res$|\.idxl$|\.gen$|\.war$|\.jar$|\.cfg$|\.appicon$|\.appinfo$|\.bat$|\.woff$|\.json$|\.pyo$|\.py$|\.a$|\.o$|\.h$|\.c$|\.aspx$|\.resx$\.ds_store$|\.shs$|\.dat$|\.gadget$|\.so$|\.dll$|\.sys$|\.idx$|\.apdisk$|\.bnp$|\.etl$|\.scr$|\.regtrans-ms$|\.scexe$|\.bzi$|\.ddz$|\.cdf-ms$|\.lock$|\.mft$|\.key$|\.evtx$|\.blf$|\.efi$|\.cdfs$|\.sfcache$|\.stl$|\.cache$|\.pat$|\.man$|\.pf$|\.mui$|\.ocx$|\.sc$|\.pbd$|\.rtp$|\.cat$|\.inf$|\.scc$|\.pcf$|\.chk$|\.ovl$|\.reg$|\.qdz$|\.rom$|\.sif$|\.alx$|\.sfc$|\.mdmp$|\.uxz$|\.mof$|\.mhx$|\.nls$|\.emm$|\.krm$|\.swp$|\.x86$|\.gpd$|\.grp$|\.vtd$|\.drv$|\.h1s$|\.pid$|\.mot$|\.cpl$|\.strings$|\.job$|\.ecd$|\.bbfw$|\.386$|\.shsh$|\.evt$|\.sha$|\.jnilib$|\.wdf$|\.wss$|\.ko$|\.bif$|\.dev$|\.mrg$|\.rfw$|\.jrs$|\.gid$|\.vmlt$|\.dt$|\.bom$|\.tlb$|\.211$|\.cb$|\.crmlog$|\.dbl$|\.hv$|\.mlb$|\.ext4$|\.rsrc$|\.src$|\.vga$|\.bin$|\.vxd$|\.log1$|\.nib$|\.pkg$|\.osc$|\.hlp$|\.bio$|\.nxp$|\.lan$|\.kext$|\.mapimail$|\.rx$|\.jlb$|\.tbs$|\.ami$|\.identifier$|\.ar$|\.spl$|\.mum$|\.bpd$|\.encr$|\.inp$|\.msc$|\.pdr$|\.lzt$|\.ann$|\.cub$|\.ime$|\.file$|\.mpkg$|\.shd$|\.nos$|\.jfs$|\.pb$|\.nxs$|\.apd$|\.osp$|\.mnu$|\.acct$|\.h1k$|\.eas$|\.esn$|\.grl$|\.gzp$|\.fstab$|\.crp$|\.ddp$|\.lls$|\.rsq$|\.rs$|\.lbr$|\.log2$|\.dio$|\.bnr$|\.ins$|\.ln$|\.prd$|\.hib$|\.qds$|\.grb$|\.hdmp$|\.uaq$|\.kdmp$|\.fs$|\.ext2$|\.htt$|\.vdx$|\.nkey$|\.jpeg$|\.gif$|\.jpg$|\.png$|\.svg$|\.ps$|\.css$|\.exif$|\.mp3$|\.wav$|\.mov$|\.wma$|\.m4a$|\.mp4$|\.html$|\.php$|\.js$|\.mydocs$|\.h1c$|\.kbd$|\.ttf$|\.pdf$|\.adm$|\.tha$|\.h1t$|\.vet$|\.fid$|\.htw$|\.prt$|\.p5x$|\.uce$|\.access$|\.bcs$|\.xmo$|\.oem$|\.bcd$|\.pol$|\.payload$|\.ina$|\.dos$|\.hhc$|\.scr$|\.ini$|\.fwl$|\.mci$|\.msn$|\.xml$|\.sam$|\.inf$|\.lgs$|\.folder$|\.rat$|\.vid$|\.cpi$|\.286$|\.rgu$|\.par$|\.dll_1029$|\.tsk$|\.prf$|\.pmr$|\.config$|\.sid$|\.icd$|\.mod$|\.000$|\.ov1$|\.h1f$|\.ion$|\.raw$|\.wcx$|\.msdm$|\.woa$|\.32s$|\.mob$|\.mrc$|\.ov5$|\.sf0$|\.1092$|\.bud$|\.zip$|\.bz2$|\.tar$|\.tar.gz$|\.gz$|\.exe$|\.prx$|\.sdb$',
        [Int] $global:MaxThreads = 10
		
    )

    function Process-List ($list)
    {
        begin{
       
            function Read-Word($file)
            {
                begin{
                    $readOnly = $true
                    $confirmConversion = $false
                    $addToRecent = $false
                    #Using Interop plays better with threading created to speed things up.
                    $null = [Reflection.Assembly]::LoadWithPartialName('Microsoft.Office.Interop.Word')
                    $objWord = New-Object -TypeName Microsoft.Office.Interop.Word.ApplicationClass
                    $objWord.Visible = $false
                    $objDoc = $objWord.Documents.Open($file, $confirmConversion, $readOnly, $addToRecent)
                    $paragraphs = $objDoc.Paragraphs
                    $contentToSearch = @()
                }
                process {
                    #Write-Host "Testing File: " $file -ForegroundColor Red
                    foreach ($paragraph in $paragraphs)
                    {
                        $contentToSearch = $paragraph.Range.Text
                        if ($contentToSearch -match $global:ccRegEx)
                        {
                            return $file
                            break
                        }
                    }
                }
                end{
                    $objDoc.ActiveDocument.Close($false)
                    $null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($objDoc)
                    $objWord.Quit()
                    $null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($objWord)
                }
            }
        
            function Read-Excel($file)
            {
                Write-Verbose -Message 'Excel-Read Called'
		    
                $connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source='"+$file+"';Extended Properties='Excel 12.0 Xml;HDR=YES;ReadOnly=TRUE'"
                $conn = New-Object -TypeName System.Data.OleDb.OleDbConnection -ArgumentList ($connectionString)
                $conn.open()
                $null = $conn.GetSchema('Tables') | 
                ForEach-Object -Process { 
                    if($_.Table_Type -eq 'TABLE') 
                    {
                        $table = $_.Table_Name
                        #Write-Host "[#] Array Length: " $tableArray.length	
                        #Write-Host "[#] Table: " $table
                        $query = 'select * from ['+$table+']'
                        $cmd = New-Object -TypeName System.Data.OleDb.OleDbCommand -ArgumentList ($query, $conn) 
                        $dataAdapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter -ArgumentList ($cmd)
                        $dataTable = New-Object -TypeName System.Data.DataTable

                        $dataAdapter.fill($dataTable)
			    
                        $columnArray = @()
                        foreach($col in $dataTable.Columns)
                        {
                            $columnArray += $col.toString()
                        }

                        $returnObject = @()
				
                        foreach($rows in $dataTable.Rows)
                        {
                            $i = 0
                            $rowObject = @{}
                            foreach($columns in $rows.ItemArray)
                            {
                                try
                                {
                                    $rowObject += @{
                                        $columnArray[$i] = $columns.toString('f0')
                                    }
                                }
                                catch
                                {

                                }
                                finally
                                {
                                    $i++
                                }
                            }  

                            $returnObject += New-Object -TypeName PSObject -Property $rowObject
                        }
                        $dataToSearch += $returnObject
                    }
                }
                $testClose = $conn.close()
	        
                if ($dataToSearch -match $global:ccRegEx)
                {
                    return $file
                }
            }
        
            function Read-NonBin($file)
            {
                $fileSize = [math]::round((Get-Item $file | Measure-Object -Sum -Property Length).Sum/1kb)		    
                if ($fileSize -lt 768)
                {
                    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file
                    while (($line = $reader.ReadLine()) -ne $null)
                    {
                        if($line -match $global:ccRegEx)
                        {
                            return $file
                            break
                        }
                    }
                    $reader.close()
                }
                else 
                {
                    $lineCount = 200000
                    $i = 0
                    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file
                    while (($line = $reader.ReadLine()) -ne $null -and $i -lt $lineCount)
                    {
                        if($line -match $global:ccRegEx)
                        {
                            return $file
                            break
                        }
                        $i++
                    }
                    $reader.close()
                }
            }

            function Test-PlainText($file)
            {
                #RegEx to test if the first few bytes contain bin data
                $plainTextRegEx = "^[\x20-\x7F]+$"
			
                $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file
                while ($line = $reader.ReadLine())
                {
                    if(!($line -match $plainTextRegEx))
                    {
                        return $false
                        break
                    }
                    else
                    {
                        return $true
                        break
                    }
                }
                $reader.close()
            }

            $CheckFileBlock = {
                param($file2, $logfile)
                $mtx = New-Object -TypeName System.Threading.Mutex -ArgumentList ($false, 'LogMutex')
                $mdbExt = '\.mdb$'
                $WordExt = '\.doc$|\.docx$'
                $ExcelExt = '\.xls$|\.xlsx$'
                $nonBinExt = '\.txt$|\.log$|\.csv$'
                $binExt = '\.mdb$|\.doc$|\.docx$|\.xls$|\.xlsx$|\.txt$|\.log$|\.csv$'
                [String] $global:ccRegEx = '\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|6(?:011|5[0-9]{2})[0-9]{12}|(?:2131|1800|35\d{3})\d{11})\b'
                #Write-Host "[#]CheckFileBlock: " $file2
			
                if(($file2 -match $ExcelExt) -and ($office -eq $true))
                {
                    $tmpExcel = Read-Excel($file2)
                    if($tmpExcel)
                    { 
                        $null = $mtx.WaitOne()
                        $tmpExcel | Out-File $logfile -Append
                        [void]$mtx.ReleaseMutex()
                    }
                }
                elseIf(($file2 -match $WordExt)  -and ($office -eq $true))
                {
                    $tmpWord = Read-Word($file2) 
                    if($tmpWord)
                    {
                        $null = $mtx.WaitOne()
                        $tmpWord | Out-File $logfile -Append
                        [void]$mtx.ReleaseMutex()
                    }
                }
                elseif($file2 -match $nonBinExt)
                {
                    $tmpNonBin = Read-NonBin($file2)
                    if($tmpNonBin)
                    {
                        $null = $mtx.WaitOne() 
                        $tmpNonBin | Out-File $logfile -Append
                        [void]$mtx.ReleaseMutex()
                    }
                }
                elseif($file2 -match $mdbExt)
                {
                    $null = $mtx.WaitOne()
                    $file2 | Out-File $logfile -Append
                    [void]$mtx.ReleaseMutex()
                }
                elseif(!($file2 -match $binExt))
                {
                    if(Test-PlainText($file2))
                    {
                        $tmpBin = Read-NonBin($file2)
                        if($tmpBin)
                        {
                            $null = $mtx.WaitOne()
                            $tmpBin |Out-File $logfile -Append
                            [void]$mtx.ReleaseMutex()
                        }
                    }
                }
                [void]$mtx.ReleaseMutex()
                $mtx.Dispose()
                $mtx.Close()
                [System.GC]::Collect()
            }

            # Adapted from:
            #   http://powershell.org/wp/forums/topic/invpke-parallel-need-help-to-clone-the-current-runspace/
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $sessionState.ApartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()
		
            # grab all the current variables for this runspace
            $MyVars = Get-Variable -Scope 1

            # these Variables are added by Runspace.Open() Method and produce Stop errors if you add them twice
            $VorbiddenVars = @('?', 'args', 'ConsoleFileName', 'Error', 'ExecutionContext', 'false', 'HOME', 'Host', 'input', 'InputObject', 'MaximumAliasCount', 'MaximumDriveCount', 'MaximumErrorCount', 'MaximumFunctionCount', 'MaximumHistoryCount', 'MaximumVariableCount', 'MyInvocation', 'null', 'PID', 'PSBoundParameters', 'PSCommandPath', 'PSCulture', 'PSDefaultParameterValues', 'PSHOME', 'PSScriptRoot', 'PSUICulture', 'PSVersionTable', 'PWD', 'ShellId', 'SynchronizedHash', 'true')

            # Add Variables from Parent Scope (current runspace) into the InitialSessionState
            ForEach($Var in $MyVars) 
            {
                If($VorbiddenVars -notcontains $Var.Name) 
                {
                    $sessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Var.name, $Var.Value, $Var.description, $Var.options, $Var.attributes))
                }
            }

            # Add Functions from current runspace to the InitialSessionState
            ForEach($Function in (Get-ChildItem -Path Function:)) 
            {
                $sessionState.Commands.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $Function.Name, $Function.Definition))
            }

            # threading adapted from
            # https://github.com/darkoperator/Posh-SecMod/blob/master/Discovery/Discovery.psm1#L407
            # Thanks Carlos!
            $counter = 0

            # create a pool of maxThread runspaces
            $pool = [runspacefactory]::CreateRunspacePool(1, $global:MaxThreads, $sessionState, $host)
            $pool.Open()
            $jobs = @()
            $ps = @()
            $wait = @()

        }	
        process{
		      
            $inArray = @()
            $inArray = $list
            
            
            if ($inArray.Length -lt 800)
            {
                $parts = 1
            }
            else
            {
                $parts = [math]::Round(($inArray.count / 1000))+1
            }

 
            $PartSize = [Math]::Ceiling($inArray.count / $parts) 

            Write-Host '[#]Loops To Perform: ' $parts

            $outArray = @()
         
            for ($i = 1; $i -le $parts; $i++) 
            { 
                $start = (($i-1)*$PartSize) 
                $end = (($i)*$PartSize) - 1 
                if ($end -ge $inArray.count) 
                {
                    $end = $inArray.count
                } 
                $outArray = @($inArray[$start..$end])
                #$outArray
                $tmpTime = Get-Date
            
                Write-Host '[#] Loop Number:' $i '('$tmpTime.ToLongTimeString()')'
                foreach ($document in $outArray)
                {
                    if ($document -ne '')
                    {
                        #Write-Host "[#] Processing: " $document
                        While ($($pool.GetAvailableRunspaces()) -le 0) 
                        {
                            Start-Sleep -Milliseconds 500
                        }

                        # create a "powershell pipeline runner"
                        $ps += [powershell]::create()

                        $ps[$counter].runspacepool = $pool

                        # add the server script block + arguments
                        [void]$ps[$counter].AddScript($CheckFileBlock).AddParameter('file2', $document).AddParameter('logfile', $out)

                        # start job
                        $jobs += $ps[$counter].BeginInvoke()

                        # store wait handles for WaitForAll call
                        $wait += $jobs[$counter].AsyncWaitHandle
				
                        $counter = $counter + 1
                    }
                    Remove-Variable -Name $tmpTime
                    Remove-Variable -Name $outArray
                } #inner filelist
            } #end of for loop
		
        }
	
        end {

            Write-Verbose -Message 'Waiting for scanning threads to finish...'

            $waitTimeout = Get-Date

            while ($($jobs | Where-Object -FilterScript {
                        $_.IsCompleted -eq $false
            }).count -gt 0 -or $($($(Get-Date) - $waitTimeout).totalSeconds) -gt 60) 
            {
                Start-Sleep -Milliseconds 500
            }
            # end async call
            for ($y = 0; $y -lt $counter; $y++) 
            {
                try 
                {
                    # complete async job
                    $ps[$y].EndInvoke($jobs[$y])
                }
                catch 
                {
                    Write-Warning -Message "error: $_"
                }
                finally 
                {
                    $ps[$y].Dispose()
                }
            }
            $pool.Dispose()
        }
    }

    function Find-Files($pts)
    {
        Get-ChildItem -Force -Recurse $pts|
        Where-Object -FilterScript {
            !($_.Name -match $FileExts)
        }|
        Where-Object -FilterScript {
            !($_.FullName -match $badPath)
        }|
        ForEach-Object -Process {
            $_.FullName
        }
    }

    $WordExt = '\.doc$|\.docx$'
    $ExcelExt = '\.xls$|\.xlsx$'
    $nonBinExt = '\.txt$|\.log$|\.csv$'
    $files = @()
    $files = Find-Files($pts)

    $startTime = Get-Date
    Write-Host "`n`n[#] Started $startTime`n"
    Write-Host '[*] Files To Process: ' $files.Length `n

    Process-List $files

    $endTime = Get-Date
    Write-Host "`n[#] Completed $endTime `n"
}

