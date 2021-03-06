<#
.Synopsis
Runs a continuous delivery build script using powerdelivery.

.Description
Runs a continuous delivery build script using powerdelivery. You should only ever
specify the first parameter of this function when running this function on your own 
computer. All other parameters are used by the TFS server.

.Example
Invoke-PowerDelivery .\MyProduct.ps1

.Parameter buildScript
The relative path to to a local powerdelivery build script to run.
#>
function Invoke-Powerdelivery {
  [CmdletBinding()]
	param(
    [Parameter(Position=0,Mandatory=0)][string] $buildScript,
    [Parameter(Position=1,Mandatory=0)][switch] $onServer = $false,
	  [Parameter(Position=2,Mandatory=0)][string] $dropLocation,
	  [Parameter(Position=3,Mandatory=0)][string] $changeSet,
	  [Parameter(Position=4,Mandatory=0)][string] $requestedBy,
	  [Parameter(Position=5,Mandatory=0)][string] $teamProject,
	  [Parameter(Position=6,Mandatory=0)][string] $workspaceName,
	  [Parameter(Position=7,Mandatory=0)][string] $environment = 'Local',
    [Parameter(Position=8,Mandatory=0)][string] $buildUri,
    [Parameter(Position=9,Mandatory=0)][string] $collectionUri,
	  [Parameter(Position=10,Mandatory=0)][string] $priorBuild
  )
	
	$logPrefix = "Powerdelivery:"
	
	$ErrorActionPreference = 'Stop'

  $isVerbose = [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference

	function InvokePowerDeliveryBuildAction($condition, $stage, $description, $status, $blockName) {
		if ($condition) {
			$actionPerformed = $false

			$powerdelivery.blockName = $blockName
			
      if ($blockName -ne "Init") {
		    Write-Host
		    Write-ConsoleSpacer
		    "= $logPrefix $status..."
	 	    Write-ConsoleSpacer
	      Write-Host
      }
			
			try {
			  if ($stage) {
		    	& $stage
					$actionPerformed = $true
				}			
				if ($blockName -eq "Compile") {
					$yamlConfig = Get-BuildConfig
					$assetOperations =  $yamlConfig.Assets

					if ($assetOperations) {
						$assetOperations.Keys | % {
							$invokeArgs = @{}

							$assetOperation = $assetOperations[$_]
							
							if ($assetOperation.Path) {
								$invokeArgs.Add('path', $assetOperation.Path)
							}
							if ($assetOperation.Destination) {
								$invokeArgs.Add('destination', $assetOperation.Destination)
							}
							if ($assetOperation.Filter) {
								$invokeArgs.Add('filter', $assetOperation.Filter)
							}
							if ($assetOperation.Recurse) {
								$invokeArgs.Add('Recurse', $true)
							}
							& Publish-BuildAssets @invokeArgs	
						}
					}
				}
				$message = "No actions performed."
			
				if ($actionPerformed) {
					$message = "Successful."
				}
			}
			finally {
			  Set-Location $powerdelivery.currentLocation
			}
		}
	}
	
	function MergeHashNested($baseHash, $subHash) {
		$mergedHash = @{}
		$baseHash.Keys | % {
			if (!$subHash.ContainsKey($_)) {
				$mergedHash.Add($_, $baseHash[$_])
			}
			else {		
				$baseHashVal = $baseHash[$_]
				if ($baseHashVal.GetType().Name -eq 'Hashtable') {
					$childMergedHash = MergeHashNested -baseHash $baseHashVal -subHash $subHash[$_]
					$mergedHash.Add($_, $childMergedHash)
				}
				else {
					$mergedHash.Add($_, $subHash[$_])
				}
			}
		}
		$subHash.Keys | % {
			if ($baseHash -eq $null -or !$baseHash.ContainsKey($_)) {
				$mergedHash.Add($_, $subHash[$_])
			}
		}
		$mergedHash
	}
	
	function ReplaceReferencedConfigSettings($yamlNodes, $replaceFor = @()) {
		
		if ($yamlNodes.Keys) {
			$replacedValues = @{}
			$yamlNodes.Keys | % {
				$yamlNode = $yamlNodes[$_]			
				if ($yamlNode.GetType().Name -eq 'Hashtable') {
          $subReplacements = $replaceFor | % { $_ }
          $subReplacements += $_
					ReplaceReferencedConfigSettings -yamlNodes $yamlNode -replaceFor $subReplacements
				}
				else {
					$matches = Select-String "\<<.*?\>>" -InputObject $yamlNode -AllMatches | Foreach {$_.Matches}

					$replacedValue = $yamlNode
					$matches | Foreach { 

						$envSettingName = $_.Value.Substring(2, $_.Length - 4)
						$envSettingValue = [String]::Empty
    
            foreach ($replacement in $replaceFor) {
              if ($envSettingName.Equals($replacement, [System.StringComparison]::InvariantCultureIgnoreCase)) {
                throw "Configuration setting $envSettingName and $replacement refer to each other causing a circular dependency"
              }
            }

            if ($envSettingName -like "Credentials:*") {
              $userName = $envSettingName.Substring(12)
              $replacedValue = Get-BuildCredentials $userName
            }
            else {
							try {
								$envSettingValue = Get-BuildSetting $envSettingName
							}
							catch {
							  if ($envSettingName -eq "BuildAppVersion") {
    					    $envSettingValue = $powerdelivery.buildAppVersion
    					 	}
						   	elseif ($envSettingName -eq "BuildEnvironment") {
						      $envSettingValue = $powerdelivery.environment
    					 	}
						   	elseif ($envSettingName -eq "BuildNumber") {
							   	$envSettingValue = $powerdelivery.buildNumber
						   	}
						   	elseif ($envSettingName -eq "BuildDropLocation") {
							   	$envSettingValue = $powerdelivery.dropLocation
						   	}
                elseif ($envSettingName -eq "CurrentLocation") {
                  $envSettingValue = $powerdelivery.currentLocation
                }
						   	else {
						   		$errorMessage = $_.Exception.Message
							    throw "Error replacing setting in module configuration file: $errorMessage"
						   	}
							}
              
              if ($envSettingValue.GetType().Name -eq 'Hashtable') {        
                $subReplacements = $replaceFor | % { $_ }
                $subReplacements += $envSettingName
                    
                $replacedValue = ReplaceReferencedConfigSettings -yamlNodes $envSettingValue -replaceFor $subReplacements
              }
              else {
                $subReplacements = $replaceFor | % { $_ }
                $subReplacements += $envSettingName

                $forwardNodes = New-Object System.Collections.Hashtable
                $forwardNodes.Add($envSettingName, $envSettingValue)

                ReplaceReferencedConfigSettings -yamlNodes $forwardNodes -replaceFor $subReplacements
						    $replacedValue = $replacedValue -replace $_, $forwardNodes[$envSettingName]
              }
            }
					}
					$replacedValues.Add($_, $replacedValue)
				}
			}
			$replacedValues.GetEnumerator() | Foreach {
				$yamlNodes[$_.Name] = $_.Value
			}
		}
	}
	
	function PrintSpaces($numSpaces, $forYaml) {
		$val = ""
		$spaceIndex = 0
		while ($spaceIndex -lt $numSpaces) {
			if (!$forYaml -and $spaceIndex -eq 0) {
      	$val += ".."
      }
      else {
				$val += ".."
      }
			$spaceIndex++
		}
		$val
	}

	function PrintConfiguration($configNodes, $depth, $forYaml) {
	
		$envMessage = ""
		
		foreach ($configSetting in $configNodes.GetEnumerator() | Sort Name) {
			$envValue = $configSetting.Value
			
			if ($envValue.GetType().Name -eq 'Hashtable') {
				$newDepth = $depth + 1
				$nestedValSpaces = PrintSpaces -numSpaces $depth -forYaml $forYaml
				$nestedVal = "$nestedValSpaces$($configSetting.Key):`r`n"
				$nestedVal += (PrintConfiguration -configNodes $envValue -depth $newDepth -forYaml $forYaml)
				$envMessage += $nestedVal
			}
			else {		
				if ($configSetting.Key.EndsWith("Password")) {
		      $envValue = '********'
	      }
				$envValWithSpaces = PrintSpaces -numSpaces $depth -forYaml $forYaml
				$envMessage += "{0}{1}: {2}`r`n" -f $envValWithSpaces, $configSetting.Key, $envValue
			}
		}
		
		$envMessage
	}

  try {

    if (!$dropLocation.EndsWith('\')) {
      $dropLocation = "$($dropLocation)\"
    }
    
    $powerdelivery.deployDriveLetter = "C"
    $powerdelivery.deployShares = @{}
    $powerdelivery.buildCredentials = @{}
    $powerdelivery.assemblyInfoFiles = @()
    $powerdelivery.currentLocation = gl
    $powerdelivery.noReleases = $true
    $powerdelivery.config = @()
    $powerdelivery.environment = $environment
    $powerdelivery.dropLocation = $dropLocation
    $powerdelivery.changeSet = $changeSet
    $powerdelivery.requestedBy = $requestedBy
    $powerdelivery.teamProject = $teamProject
    $powerdelivery.workspaceName = $workspaceName
    $powerdelivery.collectionUri = $collectionUri
    $powerdelivery.buildUri = $buildUri
    $powerdelivery.onServer = $onServer
    $powerdelivery.buildNumber = $null
    $powerdelivery.buildName = $null
    $powerdelivery.priorBuild = $priorBuild
    $powerdelivery.deployDir = Join-Path (Get-Location) "PowerDeliveryDeploy"
    $powerdelivery.isVerbose = $isVerbose

    if ((Test-Path $powerdelivery.deployDir) -and ($onServer -eq $true -or $environment -eq "Local")) {
      Remove-Item -Path $powerdelivery.deployDir -Force -Recurse | Out-Null
    }
    
    mkdir -Force $($powerdelivery.deployDir) | Out-Null

    Write-Host
    $powerdelivery.version = Get-Module powerdelivery | select version | ForEach-Object { $_.Version.ToString() }
    Write-Host "powerdelivery $($powerdelivery.version) - https://github.com/eavonius/powerdelivery"
    
    if ([String]::IsNullOrWhiteSpace($buildScript)) {
      throw "The -buildScript parameter is required."
    }

    if (!(Test-Path $buildScript)) {
      throw "The build script $buildScript does not exist."
    }

    $appScript = [System.IO.Path]::GetFileNameWithoutExtension($buildScript)
    $powerdelivery.scriptName = $appScript

    $TranscriptFile = Join-Path $powerdelivery.currentLocation "$($powerdelivery.scriptName)Build.log"
    Start-Transcript -Path $TranscriptFile

		if ($onServer -eq $true) {

		  Require-NonNullField -variable $changeSet -errorMsg "-changeSet parameter is required when running on TFS"
		  Require-NonNullField -variable $requestedBy -errorMsg "-requestedBy parameter is required when running on TFS"
		  Require-NonNullField -variable $teamProject -errorMsg "-teamProject parameter is required when running on TFS"
		  Require-NonNullField -variable $workspaceName -errorMsg "-workspaceName parameter is required when running on TFS"
		  Require-NonNullField -variable $environment -errorMsg "-environment parameter is required when running on TFS"
      Require-NonNullField -variable $collectionUri -errorMsg "-collectionUri parameter is required when running on TFS"
      Require-NonNullField -variable $buildUri -errorMsg "-buildUri parameter is required when running on TFS"
      Require-NonNullField -variable $dropLocation -errorMsg "-dropLocation parameter is required when running on TFS"
			
			if ($powerdelivery.environment -ne "Local") {
			
				LoadTFS
				
				$powerdelivery.collection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($collectionUri)
		    $powerdelivery.buildServer = $powerdelivery.collection.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
		    $powerdelivery.structure = $powerdelivery.collection.GetService([Microsoft.TeamFoundation.Server.ICommonStructureService])
				
				$buildServerVersion = $powerdelivery.buildServer.BuildServerVersion
				
				if ($buildServerVersion -eq 'v3') {
					$powerdelivery.tfsVersion = '2010'
				}
				elseif ($buildServerVersion -eq 'v4') {
					$powerdelivery.tfsVersion = '2012'
				}
				else {
					throw "TFS server must be version 2010 or 2012, a different version was detected."
				}

		    $powerdelivery.projectInfo = $powerdelivery.structure.GetProjectFromName($teamProject)
		    if (!$powerdelivery.projectInfo) {
		      throw "Project '$teamProject' not found in TFS collection '$collectionUri'"
		    }
				
				$powerdelivery.groupSecurity = $powerdelivery.collection.GetService([Microsoft.TeamFoundation.Server.IGroupSecurityService])
		    $powerdelivery.appGroups = $powerdelivery.groupSecurity.ListApplicationGroups($powerdelivery.projectInfo.Uri)
			}
	  }
	  else {
		  $powerdelivery.requestedBy = whoami
			$currentDirectory = Get-Location
			$powerdelivery.dropLocation = [System.IO.Path]::Combine($currentDirectory, "$($appScript)BuildDrop")
			
			if ($powerdelivery.environment -eq 'Local') {
				if (Test-Path $powerdelivery.dropLocation) {
					Remove-Item -Path $powerdelivery.dropLocation -Force -Recurse | Out-Null
				}
			}

			mkdir $powerdelivery.dropLocation -Force | Out-Null
			$dropLocation = $powerdelivery.dropLocation
	  }
		
		$envConfigFileName = "$($appScript)$($environment)"
		$sharedConfigFileName = "$($appScript)Shared.yml"
		$yamlFile = "$($envConfigFileName).yml"

	  if (Test-Path -Path $yamlFile) {
			$yamlPath = (Resolve-Path ".\$($yamlFile)")
      try {
        $powerdelivery.config = Get-Yaml -FromFile $yamlPath
      }
      catch { # File was empty
        $powerdelivery.config = @()
      }
	  }
		else {
			throw "Build configuration file $yamlFile not found."
	  }

	  if ($onServer) {
      Enable-PSRemoting -Force | Out-Null
      Enable-WSManCredSSP -Role Server -Force | Out-Null
	  }

    $sharedConfig = @()

		if (Test-Path -Path $sharedConfigFileName) {
      try {
		    $sharedConfig = Get-Yaml -FromFile $yamlPath -ErrorAction SilentlyContinue
      }
      catch { # File was empty
        $sharedConfig = @()
      }
			$powerdelivery.config = MergeHashNested -baseHash $sharedConfig -subHash $powerdelivery.config
		}
    else {
      throw "Build configuration file $sharedConfigFileName not found."
    }
		
		Invoke-Expression -Command ".\$appScript"

	  Write-Host "`n= Pipeline`n"
		Write-Host "Name: $appScript"
		Write-Host "Version: $($powerdelivery.buildAppVersion)"
	  
	  $scriptParams = @{}

	  $scriptParams["Requested By"] = $powerdelivery.requestedBy
	  $scriptParams["Environment"] = $powerdelivery.environment
		
		if ($onServer) {
	    $scriptParams["Team Collection"] = $powerdelivery.collectionUri
      $scriptParams["Team Project"] = $powerdelivery.teamProject
      $scriptParams["Change Set"] = $powerdelivery.changeSet
  
      $buildNameSegments = $powerdelivery.dropLocation.split('\') | where {$_}
      $buildNameIndex = $buildNameSegments.length - 1
      $buildName = $buildNameSegments[$buildNameIndex]
      $powerdelivery.buildName = $buildName
      $scriptParams["Build Name"] = $powerdelivery.buildName

      $buildNumber = $powerdelivery.buildUri.Substring($buildUri.LastIndexOf("/") + 1)
      $powerdelivery.buildNumber = $buildNumber
      $scriptParams["Build Number"] = $buildNumber
  
      if ($powerdelivery.environment -ne "Local" -and $powerdelivery.environment -ne "Commit") {
        $scriptParams["Prior Build"] = $powerdelivery.priorBuild
      }

      Write-BuildSummaryMessage -name "Application" -header "Release" -message "Version: $($powerdelivery.buildAppVersion)`nEnvironment: $($powerdelivery.environment)`nBuild: $($powerdelivery.buildNumber)"
		}
    else {

	    $now = Get-Date -Format "yyyyMMdd_hhmmss"

	    $buildNameSegments = $powerdelivery.dropLocation.split('\') | where {$_}
	    $buildNameIndex = $buildNameSegments.length - 1
	    $buildName = $buildNameSegments[$buildNameIndex]
	    $powerdelivery.buildName = "$($powerdelivery.scriptName) - $($powerdelivery.environment)_$($now)"
	    $scriptParams["Build Name"] = $powerdelivery.buildName
	  }

    ReplaceReferencedConfigSettings($powerdelivery.config)
		
		$scriptParams["Drop Location"] = $powerdelivery.dropLocation
		
    if ($scriptParams.Keys.Count -gt 0) {
      Write-ConsoleSpacer
      Write-Host "`n= Script Parameters`n"
      Write-ConsoleSpacer

      $scriptParams.Keys | % {
        Write-Host "$($_): $($scriptParams[$_])"
      }
    }

		Write-ConsoleSpacer
	  Write-Host "`n= Environment`n"
	  Write-ConsoleSpacer
        
    $configMessage = ""

    if ($powerdelivery.config.Keys.Count -gt 0) {
      $powerdelivery.config.Keys | % {
  			$configKey = $_
  			$configVal = $powerdelivery.config[$_]
  			
  			$configMessage += "`n$($configKey): "
  			
  			if ($configVal.GetType().Name -eq 'Hashtable') {
  				$configMessage += "{"
  				$configSectionNames = @()
  				$configVal.Keys | % { $configSectionNames += $_	}
  				$configMessage += $configSectionNames -join ", "
  				$configMessage += "}"
  			}
  			else {
  				if ($_ -contains "password") {
  					$configMessage += "*******"
  				}
  				else {
  					$configMessage += $configVal
  				}
  			}
  		}
    }

		$yamlContents = PrintConfiguration -configNodes $powerdelivery.config -depth 0 -forYaml $true
		$yamlContents | Out-File -FilePath (Join-Path $dropLocation "$($appScript).yml") -Encoding ASCII

    PrintConfiguration -configNodes $powerdelivery.config -depth 0 -forYaml $false

    Write-BuildSummaryMessage -name "Environment" -header "Environment Configuration" -message $configMessage

		if ($powerdelivery.environment -ne "Commit" -and $powerdelivery.onServer -eq $true) {

			$groupName = "$appScript $environment Builders"

			$buildGroup = $null
			$permitted = $false
			
			$sidSearchFactor = [Microsoft.TeamFoundation.Server.SearchFactor]::Sid
			$accountNameSearchFactor = [Microsoft.TeamFoundation.Server.SearchFactor]::AccountName
			$expandedQueryMembership = [Microsoft.TeamFoundation.Server.QueryMembership]::Expanded
			
			$requestingIdentity = $powerdelivery.groupSecurity.ReadIdentity($accountNameSearchFactor, $powerdelivery.requestedBy, $expandedQueryMembership)
			
			$powerdelivery.appGroups | % {
				if (($_.AccountName.ToLower() -eq $groupName.ToLower()) -and $buildGroup -eq $null) {
					$buildGroup = $_
					$groupMembers = $powerdelivery.groupSecurity.ReadIdentities($sidSearchFactor, $buildGroup.Sid, $expandedQueryMembership)					
					foreach ($member in $groupMembers) {
						foreach ($memberSid in $member.Members) {
							if ($memberSid -eq $requestingIdentity.Sid) {
								$permitted = $true
							}
						}
					}
        }
      }
			
			if (!$buildGroup) {
        throw "TFS Security group '$groupName' not found for project '$teamProject'. This group must exist to verify the user requesting the build is a member."
      }
			
			if (!$permitted) {
				throw "User '$($powerdelivery.requestedBy)' who queued build must be a member of TFS Security group '$groupName' to build targeting the '$environment' environment."
			}
			
	    $powerdelivery.priorBuild = $powerdelivery.buildServer.GetBuild("vstfs:///Build/Build/$priorBuild")
			
			if ($powerdelivery.priorBuild -eq $null) {
				throw "Build to promote '$priorBuild' could not be found. Are you sure you specified the build number of a prior build?"
			}
			
			$priorBuildName = $powerdelivery.priorBuild.BuildDefinition.Name.ToLower()
			
			if (!$priorBuildName.StartsWith($appScript.ToLower())) {
				throw "Prior build '$priorBuildName' is for a different product. Please specify the build number of a prior build for the same product."
			}
			
			if ($environment -eq 'Production') {
				if (!$priorBuildName.EndsWith('- test')) {
					throw "Attempt to target production with a non-test build. Please specify the build number of a prior Test environment build to promote it to production."
				}
			}
			elseif (!$priorBuildName.EndsWith('- commit')) {
				throw "Attempt to promote a non-commit build. Please specify the build number of a prior Commit environment build to promote it into this environment."
			}
		}

		InvokePowerDeliveryBuildAction -condition $true -stage $powerdelivery.init -description "Initialization" -status "Initializing" -blockName "Init"
    InvokePowerDeliveryBuildAction -condition ((($powerdelivery.environment -eq 'Commit') -and $onServer) -or $powerdelivery.environment -eq 'Local') -stage $powerdelivery.compile -description "Compilations" -status "Compiling" -blockName "Compile"
	    
    $destDropLocation = $powerdelivery.dropLocation.TrimEnd('\')
    $destCurrentLocation = $powerdelivery.currentLocation.Path.TrimEnd('\')

		if ($powerdelivery.environment -ne "Local" -and $powerdelivery.environment -ne "Commit" -and $powerdelivery.onServer) {
      $priorBuildDrop = $powerdelivery.priorBuild.DropLocation

      Write-Host "$logPrefix Cloning deployed assets from $priorBuildDrop to $destDropLocation"
      Copy-Robust $priorBuildDrop $destDropLocation -recurse
		}
        
    Write-Host "$logPrefix Retrieving assets from $destDropLocation into deploy directory"
    Copy-Robust $destDropLocation $($powerdelivery.deployDir) -recurse

		Write-Host "$logPrefix Setting location to $($powerdelivery.deployDir)"
		Set-Location $powerdelivery.deployDir

		InvokePowerDeliveryBuildAction -condition ($powerdelivery.environment -eq 'Commit' -or $powerdelivery.environment -eq 'Local') -stage $powerdelivery.testUnits -description "Unit Tests" -status "Testing Units" -blockName "TestUnits"
	  InvokePowerDeliveryBuildAction -condition $true -stage $powerdelivery.deploy -description "Deployments" -status "Deploying" -blockName "Deploy"
	  InvokePowerDeliveryBuildAction -condition $true -stage $powerdelivery.testEnvironment -description "Environment Tests" -status "Testing Environment" -blockName "TestEnvironment"
	  InvokePowerDeliveryBuildAction -condition ($environment -eq 'Commit' -or $environment -eq 'Local' -or $environment -eq 'Test') -stage $powerdelivery.testAcceptance -description "Acceptance Tests" -status "Testing Acceptance" -blockName "TestAcceptance"
	  InvokePowerDeliveryBuildAction -condition ($environment -eq 'CapacityTest') -stage $powerdelivery.testCapacity -description "Capacity Tests" -status "Testing Capacity" -blockName "TestCapacity"
        
	  Write-Host "`n$logPrefix Build succeeded!`n" -ForegroundColor DarkGreen
  }
  catch {
	  Set-Location $powerdelivery.currentLocation

    Write-Host "`n$logPrefix Build Failed!`n" -ForegroundColor Red

		$ErrorRecord = $_[0]
    $Exception = $ErrorRecord.Exception

 		if ($Exception -ne $null)
		{
 			for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
			{
        #if (![String]::IsNullOrWhiteSpace($Exception.Message)) {
		    	#Write-Host $Exception.Message
      	#}

        if ($powerdelivery.isVerbose) {
          Write-Host $Exception.GetType().FullName
          if (![String]::IsNullOrWhiteSpace($Exception.StackTrace)) {
            Write-Host $Exception.StackTrace
          }
        }
			}
		}

  	if (![String]::IsNullOrWhiteSpace($ErrorRecord.PSMessageDetails) -and $powerdelivery.isVerbose) {
  		Write-Host $ErrorRecord.PSMessageDetails
    }

    if (![String]::IsNullOrWhiteSpace($ErrorRecord.FullyQualifiedErrorId)) {
    	Write-Host "ERROR: $($ErrorRecord.FullyQualifiedErrorId)" -ForegroundColor Red
    }

    if ($powerdelivery.isVerbose) {
      Write-Host $ErrorRecord.InvocationInfo.PositionMessage
      Write-Host $ErrorRecord.ScriptStackTrace
    }

    Write-Host

		throw
  }
	finally {
		#Stop-Transcript
    if (![String]::IsNullOrWhiteSpace($TranscriptFile)) {
      if (Test-Path $TranscriptFile) {
		    Copy-Item -Force $TranscriptFile $powerdelivery.dropLocation | Out-Null
      }
    }
		Set-Location $powerdelivery.currentLocation
	}
}

<#
.Synopsis
Contains code that will execute during the Init stage of the delivery pipeline build script.

.Description
Contains code that will execute during the Init stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
Init { DoStuff() }
#>
function Init {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.init = $action
}

<#
.Synopsis
Contains code that will execute during the Compile stage of the delivery pipeline build script.

.Description
Contains code that will execute during the Compile stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
Compile { DoStuff() }
#>
function Compile {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.compile = $action
}

<#
.Synopsis
Contains code that will execute during the Deploy stage of the delivery pipeline build script.

.Description
Contains code that will execute during the Deploy stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
Deploy { DoStuff() }
#>
function Deploy {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.deploy = $action
}

<#
.Synopsis
Contains code that will execute during the TestEnvironment stage of the delivery pipeline build script.

.Description
Contains code that will execute during the TestEnvironment stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
TestEnvironment { DoStuff() }
#>
function TestEnvironment {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.testEnvironment = $action
}

<#
.Synopsis
Contains code that will execute during the TestUnits stage of the delivery pipeline build script.

.Description
Contains code that will execute during the TestUnits stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
TestUnits { DoStuff() }
#>
function TestUnits {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.testUnits = $action
}

<#
.Synopsis
Contains code that will execute during the TestAcceptance stage of the delivery pipeline build script.

.Description
Contains code that will execute during the TestAcceptance stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
TestAcceptance { DoStuff() }
#>
function TestAcceptance {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.testAcceptance = $action
}

<#
.Synopsis
Contains code that will execute during the TestCapacity stage of the delivery pipeline build script.

.Description
Contains code that will execute during the TestCapacity stage of the delivery pipeline build script.

.Parameter action
The block of script containing the code to execute.

.Example
TestCapacity { DoStuff() }
#>
function TestCapacity {
	[CmdletBinding()]
	param([Parameter(Position=0, Mandatory=1)][scriptblock] $action)
	
	$powerdelivery.testCapacity = $action
}

<#
.Synopsis
Declares a continous delivery pipeline at the top of a powerdelivery build script.

.Description
Declares a continous delivery pipeline at the top of a powerdelivery build script.

.Parameter scriptName
The name of the script being executed. Should match the .ps1 filename (without extension).

.Parameter version
The version of the product being delivered. Should include 3 version specifiers (e.g. 1.0.5)

.Example
Pipeline "MyApp" -Version "1.0.5"
#>
function Pipeline {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)][string] $scriptName,
		[Parameter(Mandatory=1)][string] $version
	)
	
	$powerdelivery.pipeline = $this
	$powerdelivery.buildAssemblyVersion = $version
	$powerdelivery.scriptName = $scriptName

	$buildAppVersion = "$appVersion"
	
    if ($environment -ne 'local') {
    	if ($onServer) {
	    	$changeSetNumber = $powerdelivery.changeSet.Substring(1)
	    	$buildAppVersion = "$($version).$($changeSetNumber)"
		}
		else {
			$changeSetNumber = "0"
			$buildAppVersion = "$($version).0"
		}
    }
	else {
		$buildAppVersion = $version
	}

    $powerdelivery.buildAppVersion = $buildAppVersion
}

Set-Alias Pow Invoke-Powerdelivery
Export-ModuleMember -Function * -Alias *