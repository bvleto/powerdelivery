#
# Module manifest for module 'PowerDelivery'
@{
ModuleToProcess = 'PowerDelivery.psm1'

# Version number of this module.
ModuleVersion = '2.2.80'

# ID used to uniquely identify this module
GUID = 'A5B89536-5B8E-4C6F-8F22-F1EAE066EB45'

# Author of this module
Author = 'Jayme C Edwards'

# Company or vendor of this module
CompanyName = 'Jayme C Edwards'

# Copyright statement for this module
Copyright = 'Copyright (c) 2013 Jayme C Edwards. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Allows you to create a continuous delivery pipeline for software products on TFS'

# Minimum version of the Windows PowerShell engine required by this module
#PowerShellVersion = '2.0'

# Minimum version of the Windows PowerShell host required by this module
#PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
#DotNetFrameworkVersion = '3.5'

# Minimum version of the common language runtime (CLR) required by this module
#CLRVersion = '2.0'

#RequiredModules = @('psake')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = @('Import-DeliveryModule', 'Get-BuildAssemblyVersion', 'Register-DeliveryModuleHook', 'Get-BuildConfig', 'Publish-BuildAssets', 'Get-BuildAssets', 'Pipeline', 'Exec', 'Get-BuildOnServer', 'Get-BuildAppVersion', 'Get-BuildEnvironment', 'Get-BuildDropLocation', 'Get-BuildChangeSet', 'Get-BuildRequestedBy', 'Get-BuildTeamProject', 'Get-BuildWorkspaceName', 'Get-BuildCollectionUri', 'Get-BuildUri', 'Get-BuildNumber', 'Get-BuildName', 'Get-BuildSetting', 'Invoke-Powerdelivery', 'Invoke-MSBuild', 'Invoke-MSTest', 'Invoke-SSISPackage', 'Enable-SqlJobs', 'Disable-SqlJobs', 'Mount-IfUNC', 'Enable-WebDeploy', 'Update-AssemblyInfoFiles', 'Publish-Roundhouse', 'Remove-Roundhouse', 'Invoke-Roundhouse', 'Write-BuildSummaryMessage', 'Publish-SSAS', 'Add-Pipeline', 'New-RemoteShare', 'Start-SqlJobs', 'Invoke-BuildConfigSections', 'Invoke-BuildConfigSection', 'Publish-WebDeploy', 'Install-NServiceBusService', 'Uninstall-NServiceBusService', 'New-WindowsUserAccount', 'Add-WindowsUserToGroup', 'Set-AppPoolIdentity', 'Get-ComputerRemoteDeployPath', 'Get-ComputerLocalDeployPath', 'Add-CredSSPTrustedHost', 'Export-BuildCredentials', 'Get-BuildCredentials', 'Remove-Pipeline', 'Update-XmlFile', 'Copy-Robust', 'Deploy-BuildAssets', 'Import-Snapin', 'Wait-ForLeapFrogBI', 'Set-EnvironmentVariable', 'Add-ExamplePipeline', 'Process-SSAS', 'Backup-MasterDataServices', 'Publish-MasterDataServices', 'Add-CommandCredSSP', 'Add-RemoteCredSSPTrustedHost', 'New-RemoteTempPath', 'Publish-SSISProject')

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

}