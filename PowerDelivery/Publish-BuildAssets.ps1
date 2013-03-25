<#
.Synopsis
Publishes build assets from the build working directory to the drop location.

.Description
Copies build assets from the build working directory to the remote UNC drop location. You should specify 
relative paths for this command.

.Parameter path
The relative local path of assets in the current directory that should be copied remotely.

.Parameter destination
The relative remote path to copy the assets to.

.Parameter filter
Optional. A filter for the file extensions that should be included.

.Example
Publish-BuildAssets "SomeDir\\SomeFiles" "SomeDir" -Filter *.*
#>
function Publish-BuildAssets {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string] $path,
		[Parameter(Position=1,Mandatory=1)][string] $destination,
		[Parameter(Position=2,Mandatory=0)][string] $filter	= $null
	)

	$currentDirectory = Get-Location
	$dropLocation = Get-BuildDropLocation
	
	$sourcePath = Join-Path $currentDirectory $path
	$destinationPath = Join-Path $dropLocation $destination
	
	mkdir -Force $destinationPath | Out-Null
	
	copy -Filter $filter -Force -Path $sourcePath -Destination $destinationPath
	
	Write-BuildSummaryMessage -name "Assets" -header "Published Assets" -message $path
}