<#
PowerDelivery.psm1

powerdelivery - http://eavonius.github.com/powerdelivery

PowerShell module that enables writing build scripts that follow continuous delivery 
principles and deploy product assets into multiple environments.
#>

if ($(get-host).version.major -lt 3) {
  throw "Powershell 3.0 or greater is required."
}

function Write-ConsoleSpacer() {
    Write-Host ('=' * $powerdelivery.sectionHeaderWidth) -ForegroundColor $powerdelivery.colors['PowerDeliveryForeground'] -BackgroundColor $powerdelivery.colors['PowerDeliveryBackground']
}

function Mount-IfUNC {
    [CmdletBinding()]
    param([Parameter(Mandatory=1)][string] $path)
	
	if ($path.StartsWith("\\")) {
		$uncPathWithoutBackslashes = $path.Substring(2)
		$pathSegments = $uncPathWithoutBackslashes -split "\\"
		$uncPath = "\\$($pathSegments[0])\$($pathSegments[1])"
	}
}

function Get-CurrentBuildDetail {

    $collectionUri = Get-BuildCollectionUri

    "Connecting to TFS server at $collectionUri..."

    $projectCollection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($collectionUri)
    $buildServer = $projectCollection.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])

    $buildUri = Get-BuildUri
    "Opening Information for Build $buildUri..."

    return $buildServer.GetBuild($buildUri)
}

function LoadTFS($vsVersion = "11.0") {

    $vsInstallDir = Get-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\VisualStudio\11.0_Config" -Name InstallDir -ErrorAction SilentlyContinue     
    if ([string]::IsNullOrWhiteSpace($vsInstallDir)) {
        $vsInstallDir = Get-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\VisualStudio\10.0_Config" -Name InstallDir -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($vsInstallDir)) {
            throw "No version of Visual Studio with the same tools as your version of TFS is installed on the build server."
        }
    }
	
    $ENV:Path += ";$($vsInstallDir.InstallDir)"

    $refAssemblies = "ReferenceAssemblies\v2.0"
    $privateAssemblies = "PrivateAssemblies"
    $tfsAssembly = Join-Path -Path $vsInstallDir.InstallDir -ChildPath "$refAssemblies\Microsoft.TeamFoundation.dll"
    $tfsClientAssembly = Join-Path -Path $vsInstallDir.InstallDir -ChildPath "$refAssemblies\Microsoft.TeamFoundation.Client.dll"
    $tfsBuildClientAssembly = Join-Path -Path $vsInstallDir.InstallDir -ChildPath "$refAssemblies\Microsoft.TeamFoundation.Build.Client.dll"
    $tfsBuildWorkflowAssembly = Join-Path -Path $vsInstallDir.InstallDir -ChildPath "$privateAssemblies\Microsoft.TeamFoundation.Build.Workflow.dll"
    $tfsVersionControlClientAssembly = Join-Path -Path $vsInstallDir.InstallDir -ChildPath "$refAssemblies\Microsoft.TeamFoundation.VersionControl.Client.dll"

    [Reflection.Assembly]::LoadFile($tfsClientAssembly) | Out-Null
    [Reflection.Assembly]::LoadFile($tfsBuildClientAssembly) | Out-Null
    [Reflection.Assembly]::LoadFile($tfsBuildWorkflowAssembly) | Out-Null
    [Reflection.Assembly]::LoadFile($tfsVersionControlClientAssembly) | Out-Null
}

$script:powerdelivery = @{}
$powerdelivery.build_success = $true
$powerdelivery.pipeline = $null

$scriptDir = Split-Path $MyInvocation.MyCommand.Path
gci $scriptDir -Filter "*.ps1" | ForEach-Object { . (Join-Path $scriptDir $_.Name) }

$sourceControlProvidersDir = Join-Path $scriptDir "SourceControlProviders"
gci $sourceControlProvidersDir -Filter "*.ps1" | ForEach-Object { . (Join-Path $sourceControlProvidersDir $_.Name) }