<#
.Synopsis
Enables SQL jobs on a Microsoft SQL database server

.Description
Enables SQL jobs on a Microsoft SQL database server. You can enable a set of jobs that matches a wildcard.

.Parameter serverName
The SQL server instance on which the jobs will be enabled.

.Parameter jobs
The jobs to enable. Can be a single job name, or a name with wildcards.

.Example
Enable-SqlJobs -serverName localhost -jobs MyJobs*
#>
function Enable-SqlJobs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=1)][string] $serverName, 
        [Parameter(Mandatory=1)][string] $jobs
    )

    $logPrefix = "Enable-SqlJobs:"
	
	[Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null

    Write-Host "$logPrefix Enabling SQL jobs with pattern $jobs on $serverName"

    $dataMartServer = New-Object Microsoft.SqlServer.Management.SMO.Server("$serverName")
    $dataMartJobs = $dataMartServer.jobserver.jobs | where-object {$_.name -like "$jobs"}
    foreach ($dataMartJob in $dataMartJobs)	{	
        $jobName = $dataMartJob.Name
        $dataMartJob.IsEnabled = $true
        $dataMartJob.Alter()
        Write-Host "$logPrefix Job '$jobName' successfully enabled."
    }
}

Export-ModuleMember -Function Enable-SqlJobs