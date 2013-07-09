<#
.Synopsis
Runs an SSIS package using dtexec.exe.

.Description
The Invoke-SSIS cmdlet is used to execute a Microsoft SQL Server Integration Services (SSIS) package. This cmdlet runs dtexec.exe on a remote computer.

Copy your .dtsx packages to a UNC share within the Deploy block of your script onto each computer you wish to run packages on.

.Parameter package
A path local to the remote server the package is being executed on. If you had a UNC share on that server "\\MyServer\MyShare" and it was mapped to "D:\Somepath", use "D:\Somepath" here.

.Parameter server
The computer name onto which to execute the package. This computer must have PowerShell 3.0 with WinRM installed, and allow execution of commands from the TFS build server and the account under which the build agent service is running.

.Parameter dtExecPath
The path to dtexec.exe on the server to run the command.

.Parameter packageArgs
Optional. A PowerShell hash containing name/value pairs to set as package arguments to dtexec.

.Example
Invoke-SSIS -package MyPackage.dtsx -server MyServer -packageArgs @{MyCustomArg = SomeValue}
#>
function Invoke-SSISPackage {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string] $package, 
        [Parameter(Position=1,Mandatory=1)][string] $server, 
        [Parameter(Position=2,Mandatory=1)][string] $dtExecPath, 
        [Parameter(Position=3,Mandatory=0)][string] $packageArgs
    )

    Invoke-Command -ComputerName $server -ScriptBlock {

        $innerPackage = $using:package
        $innerDTExecPath = $using:dtExecPath
        $innerPackageArgs = $using:packageArgs

	    $packageExecStatement = "& ""$innerDTExecPath"" /File '$innerPackage'"
	
	    if ($innerPackageArgs) {
		    $packageExecStatment += " $innerPackageArgs"
	    }

        Invoke-Expression -Command $packageExecStatement

        if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
            throw "Error executing SSIS package, exit code was $LASTEXITCODE"
        }
    }

    Write-BuildSummaryMessage -name "Packages" -header "Packages" -message "SSIS: $package -> $server"
}