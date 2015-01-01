<#
.Synopsis
Invokes a PowerShell cmdlet passing a section of YAML from the build environment configuration as arguments to it.

.Description
Invokes a PowerShell cmdlet passing a section of YAML from the build environment configuration as arguments to it.

.Parameter section
hash - Each value of the hash will be passed to the cmdlet as arguments.

.Parameter cmdlet
string - The name of the cmdlet to invoke.

.Example
In the example below, there is a YAML configuration section named "Database" with 
settings that match the arguments of the "Invoke-Roundhouse" cmdlet.

$database = pow:getSetting Database
pow:do Invoke-Roundhouse $database
#>
function Invoke-BuildConfigSection {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string] $cmdlet,
		[Parameter(Position=1,Mandatory=1)] $section,
		[Parameter(Position=2,Mandatory=0)][switch] $multiple
	)

	if ($section.GetType().Name -eq 'String') {
		$section = pow:getSetting $section
	}
	
	$sections = @($section)

	if ($multiple) {
		$sections = @($section.Values)
	}

	$sections | % {
		$currentSection = $_
		$invokeArgs = @{}
		if ($currentSection.Keys) {
			$currentSection.Keys | % {
				$sectionValue = $currentSection[$_]
				if ($sectionValue.GetType().Name -ne 'Hashtable' -and $sectionValue.StartsWith(":")) {
					$present = $sectionValue.Substring(1)
					$isPresent = [boolean]$present
					$switchParameter = New-Object System.Management.Automation.SwitchParameter -ArgumentList @($isPresent)
					$invokeArgs.Add($_, $switchParameter)
				}
				else {
					$invokeArgs.Add($_, $currentSection[$_])	
				}
			}
		}
		Invoke-Expression "& $cmdlet @invokeArgs"
	}
}

Set-Alias pow:do Invoke-BuildConfigSection
Export-ModuleMember -Function Invoke-BuildConfigSection -Alias pow:do