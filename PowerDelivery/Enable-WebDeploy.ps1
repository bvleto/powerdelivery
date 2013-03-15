<#
.Synopsis
Sets up an IIS server to allow web deployment via msdeploy.exe.

.Description
The Enable-WebDeploy cmdlet is used to configure an IIS website for deployment.

.Example
Enable-WebDeploy -webComputer 'MyWebServer' -webDeployDir 'C:\Program Files\Microsoft Web Deploy v3' -webSite 'MySite' -webPort '8080' -webPassword '3F#g&jKl'

.Parameter webComputer
The name of the computer to enable web deployment for. Must be Windows Server running IIS 7 or greater, with Web Deploy 3.0 and "Recommended Host Configuration" setup using Microsoft Platform Installer.

.Parameter webDeployDir
The directory on the web server computer into which Web Deploy 3 is installed. You can use a remote powershell command to read this out of the registry of the remote computer if your different enviroments have installed it in different locations.

.Parameter webSite
The name of the website to create. A corresponding application pool with the same name will also be created.

.Parameter webPort
The port the website should run on. Must not be an existing port in use on the server.

.Parameter webPassword
A user account will be created on the server that will allow deployment to it named after the website. This paramter specifies the password of that account.

.Parameter runtimeVersion
Optional. The version of .NET the application pool should be created with. Defaults to '4.0'.
#>
function Enable-WebDeploy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=1)][string] $webComputer, 
        [Parameter(Mandatory=1)][string] $webDeployDir, 
        [Parameter(Mandatory=1)][string] $webSite, 
        [Parameter(Mandatory=1)][string] $webPort, 
        [Parameter(Mandatory=1)][string] $webPassword, 
        [Parameter(Mandatory=0)][string] $runtimeVersion = '4.0'
    )

    $webDeployScriptsDir = "$webDeployDir\Scripts"
    $siteSetupArgs = "-siteName $webSite -publishSettingSavePath C:\Inetpub\$webSite -publishSettingFileName $($webSite).publishsettings -sitePhysicalPath C:\Inetpub\$webSite -sitePort $webPort -siteAppPoolName $webSite -deploymentUserName $webSite -deploymentUserPassword '$($webPassword)' -managedRunTimeVersion v$runtimeVersion"
    $setupSiteResult = Invoke-Expression -Command "Invoke-Command -ComputerName $webComputer -ScriptBlock { & ""$webDeployScriptsDir\SetupSiteForPublish.ps1"" $siteSetupArgs }"
}