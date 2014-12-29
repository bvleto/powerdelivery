<#
.Synopsis
Runs an SSIS package using dtexec.exe.

.Description
The Invoke-SSIS cmdlet is used to execute a Microsoft SQL Server Integration Services (SSIS) package. This cmdlet runs dtexec.exe on a remote computer.

Copy your .dtsx packages to a UNC share within the Deploy block of your script onto each computer you wish to run packages on.

.Parameter package
A path local to the remote server the package is being executed on. If you had a UNC share on that server "\\MyServer\MyShare" and it was mapped to "D:\Somepath", use "D:\Somepath" here.

.Parameter computerName
The computer name(s) onto which to execute the package. If not "localhost", this computer must have PowerShell 3.0 with WinRM installed, allow execution of commands from the TFS build server and the account under which the build agent service is running.

.Parameter dtExecPath
The path to dtexec.exe on the server to run the command.

.Parameter packageArgs
Optional. A PowerShell hash containing name/value pairs to set as package arguments to dtexec.

.Example
Invoke-SSIS -package MyPackage.dtsx -ComputerName MyServer -packageArgs @{MyCustomArg = SomeValue}
#>
function Invoke-SSISPackage {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string] $package, 
        [Parameter(Position=1,Mandatory=1)][string] $computerName, 
        [Parameter(Position=2,Mandatory=1)][string] $dtExecPath, 
        [Parameter(Position=4,Mandatory=0)][string] $packageArgs
    )
    
    Set-Location $powerdelivery.deployDir
    
    $logPrefix = "[Invoke-SSISPackage]"

    $computerNames = $computerName -split "," | % { $_.Trim() }

    $logFileName = [System.IO.Path]::GetFileNameWithoutExtension("$package") + ".log"
    $dropLogPath = [System.IO.Path]::GetDirectoryName("$package")

    foreach ($curComputerName in $computerNames) {

        if ($curComputerName -ne 'localhost') {
          $remoteTempPath = New-RemoteTempPath $curComputerName $package
        }
        else {
          $packageWithDir = Join-Path (Get-Location) $package
          $remoteTempPath = [System.IO.Path]::GetDirectoryName($packageWithDir)
          $dropLogPath = $remoteTempPath
        }

        $invokeArgs = @{
            "ComputerName" = $curComputerName;
            "ArgumentList" = @($logPrefix, $package, $dtExecPath, $packageArgs, $dropLogPath, $remoteTempPath, $logFileName);
            "ScriptBlock" = {
                param($logPrefix, $package, $dtExecPath, $packageArgs, $dropLogPath, $remoteTempPath, $logFileName)

                $remoteLogFile = Join-Path "$remoteTempPath" "$logFileName"

                # Delete the prior temporary log file if one exists
                #
                if (Test-Path -Path "$remoteLogFile") {
                    Remove-Item -Path "$remoteLogFile" -Force | Out-Null
                }

                $innerPackage = $package
                $innerDTExecPath = $dtExecPath
                $innerPackageArgs = $packageArgs

                $packageExecStatement = """$innerDTExecPath"" /File '$innerPackage'"
            
                if ($innerPackageArgs) {
                    $packageExecStatment += " $innerPackageArgs"
                }

                $packageExecStatement +=  " | Out-File ""$remoteLogFile"""

                Write-Host "$varLogPrefix $packageExecStatement"
                Invoke-Expression "& $packageExecStatement"

                $ssisFailed = $false

                if ($lastexitcode -ne 0) {
                    $ssisFailed = $true
                }

                # Copy the SSIS log file from the temporary directory to the directory it was executed from.
                #
                if (Test-Path $remoteLogFile) {
                    if ([System.IO.Path]::GetDirectoryName("$remoteLogFile") -ne $dropLogPath) {
                        if (!(Test-Path "$dropLogPath")) {
                            New-Item -ItemType Directory -Path $dropLogPath | Out-Null
                        }
                        Write-Host "$varLogPrefix $remoteLogFile -> $dropLogPath"
                        Copy-Item "$remoteLogFile" "$dropLogPath"
                    }
                }

                if ($ssisFailed) {
                    throw ("SSIS Package $package failed. See the log file at $remoteLogFile.")
                }
            };
            "ErrorAction" = "Stop"
        }

        if ($curComputerName -eq 'localhost') {
          $invokeArgs.Remove("ComputerName")
        }

        Invoke-Command @invokeArgs

        Write-BuildSummaryMessage "$package ($curComputerName)"
    }
}

Export-ModuleMember -Function Invoke-SSISPackage