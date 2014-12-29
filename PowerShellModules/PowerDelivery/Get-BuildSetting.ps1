<#
.Synopsis
Gets a configuration setting from the YML files for the environment 
the currently executing build is targeting for deployment.

.Description
Gets a configuration setting from the YML files for the environment 
the currently executing build is targeting for deployment.

.Parameter name
The name of the setting from the YML file to get.

.Parameter throwIfNotFound
Whether to throw an exception if the setting is not found. Defaults to true.

.Outputs
The value of the setting from the YML file for the setting that was 
requested.

.Example
$webServerName = Get-BuildSetting WebServerName
#>
function Get-BuildSetting {
    [CmdletBinding()]
    param(
      [Parameter(Position=0,Mandatory=1)][string] $name,
      [Parameter(Position=1,Mandatory=0)][bool] $throwIfNotFound = $true
    )

	if (!$powerdelivery.config.ContainsKey($name)) {
    if ($throwIfNotFound) {
		  throw "Couldn't find build setting '$name'"
    }
    else {
      $null
    }
	}
  else {
  	$powerdelivery.config[$name]
  }
}

Set-Alias pow:getSetting Get-BuildSetting
Export-ModuleMember -Function Get-BuildSetting -Alias pow:getSetting