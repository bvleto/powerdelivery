<#
.Synopsis
Executes a command line executable. Original source included in psake (https://github.com/psake/psake).

.Description
Executes a command line executable. Throws an exception if a non-zero exit code is encountered.

.Parameter cmd
The command to execute.

.Parameter errorMessage
Optional. The error message to return in the exception if you wish to override the default.

.Parameter logCommand
Optional. Default is false. When set, causes the command itself to be written to the console and as a build summary message.

.Example
Exec -errorMessage "Failed to compile MyProject" {
	msbuild.exe MyProject.proj /v:m
}
#>
function Exec {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ("Error executing command {0}" -f $cmd),
        [Parameter(Position=2,Mandatory=0)][switch]$logCommand = $false
    )

    $action = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)

    if ($logCommand) {
        Write-BuildSummaryMessage $cmd -actionName $action
    }

    & $cmd
    
    if ($lastexitcode -ne 0) {
        throw ("Exec: " + $errorMessage)
    }
}

Export-ModuleMember -Function Exec