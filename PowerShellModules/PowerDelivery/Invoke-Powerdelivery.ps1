<#
.Synopsis
Runs a continuous delivery build script using powerdelivery. Alias is "pow".

.Description
Runs a continuous delivery build script using powerdelivery. You should only ever
specify the first parameter of this function when running this function on your own 
computer. All other parameters are used by the TFS server.

.Example
pow .\MyProduct.ps1

.Parameter buildScript
The relative path to to a local powerdelivery build script to run.

.Parameter environment
The environment to target. Must be 'Commit', 'Test', 'CapacityTest', or 'Production'.
#>
function Invoke-Powerdelivery
{
  [CmdletBinding()]
  param(
    [Parameter(Position=0,Mandatory=0)][string] $BuildScript,
    [Parameter(Position=1,Mandatory=0)][string] $Environment = 'Local',
    [Parameter(Position=2,Mandatory=0)] $Parameters = @{},
    [Parameter(Position=3,Mandatory=0)][string] $PriorBuild,
    [Parameter(Position=4,Mandatory=0)][switch] $OnServer = $false
  )

  $product = "PowerDelivery"

  $logPrefix = "[$product]"

  $curDir = Get-Location
  $deployFolder = "$product\Deploy"
  $dropsFolder = "$product\Drops"

  $ErrorActionPreference = 'Stop'

  # Prints the header of the console application header
  #
  function PrintConsoleAppHeader
  {
    $powerdelivery.currentLocation = $curDir
    $powerdelivery.lastAction = ''
    $powerdelivery.summaryContent = ''
    $powerdelivery.isBuildSummarySectionStarted = $false
    $powerdelivery.version = Get-Module powerdelivery | select version | ForEach-Object { $_.Version.ToString() }

    Start-BuildSummarySection Pipeline
    Write-BuildSummaryMessage "$product $($powerdelivery.version)"
    Write-Host "[Invoke-Powerdelivery] Type ""get-help pow"" or visit https://github.com/eavonius/powerdelivery for help."
    Write-BuildSummaryMessage "Starting in $($powerdelivery.currentLocation)"
  }

  # Initializes variables at the start of the build.
  #
  function InitializeBuild
  {
    $powerdelivery.assemblyInfoFiles = @()
    $powerdelivery.buildCredentials = @{}
    $powerdelivery.colors = @{'PowerDeliveryForeground' = 'Green'; 'PowerDeliveryBackground' = 'Black'}
    $powerdelivery.config = @{}
    $powerdelivery.deployDir = Join-Path $powerdelivery.currentLocation $deployFolder
    $powerdelivery.deployDriveLetter = "C"
    $powerdelivery.deployShares = @{}
    $powerdelivery.environment = $Environment
    $powerdelivery.isVerbose = [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference
    $powerdelivery.noReleases = $true
    $powerdelivery.onServer = $OnServer
    $powerdelivery.priorBuild = $PriorBuild
    $powerdelivery.requestedBy = whoami
    $powerdelivery.sectionHeaderWidth = 40
    $powerdelivery.startedAt = Get-Date -Format "yyyyMMdd_hhmmss"
    $powerdelivery.startedAtDate = Get-Date
    $powerdelivery.sourceControlProviders = @()
    
    if ([String]::IsNullOrWhiteSpace($BuildScript))
    {
      throw "The -buildScript parameter is required."
    }

    if (!(Test-Path $BuildScript))
    {
      throw "The build script $BuildScript does not exist."
    }

    $powerdelivery.scriptName = [System.IO.Path]::GetFileNameWithoutExtension($BuildScript)
    $powerdelivery.buildName = "$($powerdelivery.scriptName)_$($powerdelivery.environment)_$($powerdelivery.startedAt)"

    # Initialize PowerShell remoting if targeting a non-local build.
    #
    if ($powerdelivery.environment -ne 'Local')
    {
      Enable-PSRemoting -Force | Out-Null
      Enable-WSManCredSSP -Role Server -Force | Out-Null
    }
  }

  # Resets the deploy directory during a local or server build.
  #
  function ResetDeployDirectory
  {
    $deployDir = $powerdelivery.deployDir

    if ((Test-Path $deployDir) -and ($powerdelivery.onServer -or $powerdelivery.environment -eq 'Local'))
    {
      Remove-Item -Path "$deployDir\*" -Force -Recurse | Out-Null
    }

    mkdir -Force $deployDir | Out-Null
  }

  # Starts logging of the build output to a transcript file.
  #
  function StartTranscript
  {
    $transcriptFile = Join-Path $powerdelivery.deployDir "$($powerdelivery.scriptName)Build.log"
    
    Start-Transcript -Path $transcriptFile | Out-Null

    Write-BuildSummaryMessage "Logging to $(Print-BuildPath $TranscriptFile)"
  }

  # Writes the build summary HTML file.
  #
  function WriteBuildSummary
  {
    End-BuildSummarySection

    $scriptName = $powerdelivery.scriptName

    $buildSummaryPath = Join-Path $powerdelivery.deployDir "$($scriptName)Build.html"

    $summaryContent = $powerdelivery.summaryContent

    @"
<!DOCTYPE html>
<html lang='en'>
    <head>
        <meta charset='utf-8'>
        <meta http-equiv='X-UA-Compatible' content='IE=edge'>
        <meta http-equiv='content-type' content='text/html; charset=UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>$scriptName - PowerDelivery Build Summary</title>
        <link href='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/css/bootstrap.min.css' rel='stylesheet' charset='utf-8'>
        <link href='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/css/bootstrap-theme.min.css' rel='stylesheet' charset='utf-8'>
        <style>
        ul.list-group, ul.list-group li.list-group-item {
          border: 0px;
          -webkit-box-shadow: none;
          box-shadow: none;
        }
        </style>
        <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
        <!--[if lt IE 9]>
          <script src='http://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js'></script>
          <script src='http://oss.maxcdn.com/respond/1.4.2/respond.min.js'></script>
        <![endif]-->
    </head>
    <body>
        <div class='container'>
            <h4>Powerdelivery Build Summary</h4>
            <h1>$scriptName</h1>
            <p>Started by $(whoami) on $($powerdelivery.startedAtDate)</p>
            $summaryContent
        </div>
        <script src='http://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js' charset='utf-8'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/js/bootstrap.min.js' charset='utf-8'></script>
    </body>
</html>
"@ | Out-File -FilePath $buildSummaryPath

    Write-Host "[Invoke-PowerDelivery] Wrote build summary to $(Print-BuildPath $buildSummaryPath)"
  }

  # Register the built-in source control providers.
  # Module authors can register their own in their module.
  #
  function RegisterSourceControlProviders
  {
    Register-SourceControlProvider Git
    Register-SourceControlProvider TFS
  }

  # Creates the drop location if a local build.
  #
  function CreateLocalDropFolder
  {
    if (!$powerdelivery.onServer)
    {
      $dropLocation = [System.IO.Path]::Combine($powerdelivery.currentLocation, $dropsFolder)

      $powerdelivery.dropLocation = $dropLocation

      mkdir $dropLocation -Force | Out-Null

      Write-BuildSummaryMessage "Created $(Print-BuildPath $dropLocation)"
    }
  }

  # Loads the build's configuration files.
  #
  function LoadBuildConfiguration
  {
    $powerdelivery.sharedConfigFileName = "$($powerdelivery.scriptName)Shared.yml"
    $powerdelivery.environmentConfigFileName = "$($powerdelivery.scriptName)$($Environment).yml"

    # Load environment-specific configuration

    $environmentConfigFullPath = Join-Path $powerdelivery.currentLocation $powerdelivery.environmentConfigFileName

    if (!(Test-Path -Path $environmentConfigFullPath))
    {
      throw "Build configuration file $($powerdelivery.environmentConfigFileName) not found."
    }

    Write-BuildSummaryMessage "Loaded $(Print-BuildPath $environmentConfigFullPath)"

    $powerdelivery.config = Get-Yaml -FromFile $environmentConfigFullPath

    # Load shared configuration

    $sharedConfigFullPath = Join-Path $powerdelivery.currentLocation $powerdelivery.sharedConfigFileName

    if (!(Test-Path -Path $sharedConfigFullPath))
    {
      throw "Build configuration file $($powerdelivery.sharedConfigFileName) not found."
    }

    Write-BuildSummaryMessage "Loaded $(Print-BuildPath $sharedConfigFullPath)..."

    $sharedConfig = Get-Yaml -FromFile $sharedConfigFullPath

    # Merge configuration

    $powerdelivery.config = MergeHashNested -baseHash $sharedConfig -subHash $powerdelivery.config
  }

  # Creates the drop location to place compiled assets into.
  #
  function CreateBuildDropFolder
  {
    if ($powerdelivery.environment -ne 'Local')
    {
      $powerdelivery.dropLocation = Get-BuildSetting DropLocation $false

      if ($powerDelivery.dropLocation -eq $null)
      {
        throw "DropLocation configuration missing from $sharedConfigFileName."
      }
    }

    $powerdelivery.dropLocation = Join-Path $powerdelivery.dropLocation $powerdelivery.buildName

    # Delete the drop location if a local build
    #
    if ($powerdelivery.environment -eq 'Local')
    {
      if (Test-Path $powerdelivery.dropLocation)
      {
        Remove-Item -Path $powerdelivery.dropLocation -Force -Recurse | Out-Null
      }
    }

    New-Item -Force -ItemType Directory -Path $powerdelivery.dropLocation -ErrorAction SilentlyContinue | Out-Null

    Write-BuildSummaryMessage "Created drop folder $(Print-BuildPath $powerdelivery.dropLocation)"
  }

  # Runs the delivery pipeline build script.
  #
  function InvokeBuildScript
  {
    Invoke-Expression -Command ".\$($powerdelivery.scriptName)"
  }

  # Initializes the source control provider used by the build.
  #
  function InitializeSourceControlProvider
  {
    $powerdelivery.sourceControl = Get-BuildSetting SourceControl $false
    if ($powerdelivery.sourceControl -eq $null)
    {
      throw "SourceControl configuration missing from .yml files."
    }

    $providerName = $powerdelivery.sourceControl['Provider']   
    if ($providerName -eq $null)
    {
      throw "ProviderName missing from SourceControl configuration in .yml files."
    }

    iex "Initialize-$($providerName)SourceControlProvider"
  }

  # Writes the merged configuration to the drop location.
  #
  function WriteMergedConfiguration
  {
    ApplyConfigurationReplacements -yamlNodes $powerdelivery.config
    
    $yamlContents = PrintConfiguration -configNodes $powerdelivery.config -depth 0

    $mergedConfigPath = Join-Path $powerdelivery.dropLocation "$($powerdelivery.scriptName).yml"

    $yamlContents | Out-File -FilePath $mergedConfigPath -Encoding ASCII

    Write-BuildSummaryMessage "Merged configuration to $(Print-BuildPath $mergedConfigPath)"
  }

  # Validates that a build being requested to be promoted may be.
  #
  function ValidateBuildPromotion
  {
    if ($powerdelivery.environment -ne "Commit" -and $powerdelivery.onServer)
    {
      # TODO: Use the powerdelivery service and source control provider API here.

      $groupName = "$($powerdelivery.scriptName) $Environment Builders"

      $buildGroup = $null
      $permitted = $false
      
      $sidSearchFactor = [Microsoft.TeamFoundation.Server.SearchFactor]::Sid
      $accountNameSearchFactor = [Microsoft.TeamFoundation.Server.SearchFactor]::AccountName
      $expandedQueryMembership = [Microsoft.TeamFoundation.Server.QueryMembership]::Expanded
      
      $requestingIdentity = $powerdelivery.groupSecurity.ReadIdentity($accountNameSearchFactor, $powerdelivery.requestedBy, $expandedQueryMembership)
      
      $powerdelivery.appGroups | % {
        if (($_.AccountName.ToLower() -eq $groupName.ToLower()) -and $buildGroup -eq $null)
        {
          $buildGroup = $_
          $groupMembers = $powerdelivery.groupSecurity.ReadIdentities($sidSearchFactor, $buildGroup.Sid, $expandedQueryMembership)

          foreach ($member in $groupMembers)
          {
            foreach ($memberSid in $member.Members)
            {
              if ($memberSid -eq $requestingIdentity.Sid)
              {
                $permitted = $true
              }
            }
          }
        }
      }
      
      if (!$buildGroup)
      {
        throw "TFS Security group '$groupName' not found for project '$teamProject'. This group must exist to verify the user requesting the build is a member."
      }
      
      if (!$permitted)
      {
        throw "User '$($powerdelivery.requestedBy)' who queued build must be a member of TFS Security group '$groupName' to build targeting the '$Environment' environment."
      }
      
      $powerdelivery.priorBuild = $powerdelivery.buildServer.GetBuild("vstfs:///Build/Build/$PriorBuild")
      
      if ($powerdelivery.priorBuild -eq $null)
      {
        throw "Build to promote '$PriorBuild' could not be found. Are you sure you specified the build number of a prior build?"
      }
      
      $PriorBuildName = $powerdelivery.priorBuild.BuildDefinition.Name.ToLower()
      
      if (!$PriorBuildName.StartsWith($powerdelivery.scriptName.ToLower()))
      {
        throw "Prior build '$PriorBuildName' is for a different product. Please specify the build number of a prior build for the same product."
      }
      
      if ($Environment -eq 'Production')
      {
        if (!$PriorBuildName.EndsWith('- test'))
        {
          throw "Attempt to target production with a non-test build. Please specify the build number of a prior Test environment build to promote it to production."
        }
      }
      elseif (!$PriorBuildName.EndsWith('- commit'))
      {
        throw "Attempt to promote a non-commit build. Please specify the build number of a prior Commit environment build to promote it into this environment."
      }
    }
  }

  # Invokes a block of script from the delivery pipeline build script.
  #
	function InvokeBuildScriptBlock($condition, $stage, $description, $status, $blockName)
  {
		if ($condition)
    {
			$actionPerformed = $false

			$powerdelivery.blockName = $blockName
			
      if ($blockName -ne "Init")
      {
		    PrintSectionHeader "$status..."
      }
			
			try
      {
			  if ($stage)
        {
		    	& $stage
					$actionPerformed = $true
				}			
				if ($blockName -eq "Compile")
        {
					$yamlConfig = Get-BuildConfig
					$assetOperations =  $yamlConfig.Assets

					if ($assetOperations)
          {
						$assetOperations.Keys | % {
							$invokeArgs = @{}

							$assetOperation = $assetOperations[$_]
							
							if ($assetOperation.Path)
              {
								$invokeArgs.Add('path', $assetOperation.Path)
							}
							
              if ($assetOperation.Destination)
              {
								$invokeArgs.Add('destination', $assetOperation.Destination)
							}
							
              if ($assetOperation.Filter)
              {
								$invokeArgs.Add('filter', $assetOperation.Filter)
							}
							
              if ($assetOperation.Recurse)
              {
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
	
  # Recursively merges the shared and environment-specific build configuration.
  #
	function MergeHashNested($baseHash, $subHash)
  {
		$mergedHash = @{}
		
    $baseHash.Keys | % {
			if (!$subHash.ContainsKey($_))
      {
				$mergedHash.Add($_, $baseHash[$_])
			}
			else
      {
				$baseHashVal = $baseHash[$_]

				if ($baseHashVal.GetType().Name -eq 'Hashtable')
        {
					$childMergedHash = MergeHashNested -baseHash $baseHashVal -subHash $subHash[$_]
					$mergedHash.Add($_, $childMergedHash)
				}
				else
        {
					$mergedHash.Add($_, $subHash[$_])
				}
			}
		}

		$subHash.Keys | % {
			if ($baseHash -eq $null -or !$baseHash.ContainsKey($_))
      {
				$mergedHash.Add($_, $subHash[$_])
			}
		}
		$mergedHash
	}
	
  # Replaces settings in configuration files that use the replacement syntax (<<my-value>>)
  #
	function ApplyConfigurationReplacements($yamlNodes, $replaceFor = @())
  {
    $buildAppVersion = $powerdelivery.buildAppVersion
    $environment = $powerdelivery.environment
    $dropLocation = $powerdelivery.dropLocation
    $currentLocation = $powerdelivery.currentLocation

		if ($yamlNodes.Keys)
    {
			$replacedValues = @{}

			$yamlNodes.Keys | % {

				$yamlNode = $yamlNodes[$_]

				if ($yamlNode.GetType().Name -eq 'Hashtable')
        {
          $subReplacements = $replaceFor | % { $_ }
          $subReplacements += $_
					ApplyConfigurationReplacements -yamlNodes $yamlNode -replaceFor $subReplacements
				}
				else
        {
					$matches = Select-String "\<<.*?\>>" -InputObject $yamlNode -AllMatches | % {$_.Matches}

					$replacedValue = $yamlNode

					$matches | % {

						$envSettingName = $_.Value.Substring(2, $_.Length - 4)
						$envSettingValue = [String]::Empty
    
            foreach ($replacement in $replaceFor)
            {
              if ($envSettingName.Equals($replacement, [System.StringComparison]::InvariantCultureIgnoreCase))
              {
                throw "Configuration setting $envSettingName and $replacement refer to each other causing a circular dependency"
              }
            }

            if ($envSettingName -like "Credentials:*")
            {
              $userName = $envSettingName.Substring(12)
              $replacedValue = Get-BuildCredentials $userName
            }
            else
            {
							try
              {
								$envSettingValue = Get-BuildSetting $envSettingName
							}
							catch
              {
							  if ($envSettingName -eq "BuildAppVersion")
                {
    					    $envSettingValue = $buildAppVersion
    					 	}
						   	elseif ($envSettingName -eq "BuildEnvironment")
                {
						      $envSettingValue = $environment
    					 	}
						   	elseif ($envSettingName -eq "BuildNumber")
                {
							   	$envSettingValue = $buildAppVersion
						   	}
						   	elseif ($envSettingName -eq "BuildDropLocation")
                {
							   	$envSettingValue = $dropLocation
						   	}
                elseif ($envSettingName -eq "CurrentLocation")
                {
                  $envSettingValue = $currentLocation
                }
						   	else
                {
						   		$errorMessage = $_.Exception.Message
							    throw "Error replacing setting in module configuration file: $errorMessage"
						   	}
							}
              
              if ($envSettingValue.GetType().Name -eq 'Hashtable')
              {
                $subReplacements = $replaceFor | % { $_ }
                $subReplacements += $envSettingName
                    
                $replacedValue = ApplyConfigurationReplacements -yamlNodes $envSettingValue -replaceFor $subReplacements
              }
              else
              {
                $subReplacements = $replaceFor | % { $_ }
                $subReplacements += $envSettingName

                $forwardNodes = New-Object System.Collections.Hashtable
                $forwardNodes.Add($envSettingName, $envSettingValue)

                ApplyConfigurationReplacements -yamlNodes $forwardNodes -replaceFor $subReplacements
						    $replacedValue = $replacedValue -replace $_, $forwardNodes[$envSettingName]
              }
            }
					}
					$replacedValues.Add($_, $replacedValue)
				}
			}
			
      $replacedValues.GetEnumerator() | % {
				$yamlNodes[$_.Name] = $_.Value
			}
		}
	}

  # Prints a section header for the build log.
  #
  function PrintSectionHeader($text)
  {
    Start-BuildSummarySection $text
  }
	
  # Prints the configuration of the build for logging.
  #
	function PrintConfiguration($configNodes, $depth)
  {
		$envMessage = ""
		
		foreach ($configSetting in $configNodes.GetEnumerator())
    {
			$envValue = $configSetting.Value
			
			if ($envValue.GetType().Name -eq 'Hashtable')
      {
				$newDepth = $depth + 1
				$nestedValSpaces = " " * $depth
				$nestedVal = "$nestedValSpaces$($configSetting.Key):`r`n"
				$nestedVal += (PrintConfiguration -configNodes $envValue -depth $newDepth)
				$envMessage += $nestedVal
			}
			else
      {
				if ($configSetting.Key.EndsWith("Password"))
        {
		      $envValue = '********'
	      }
				$envValWithSpaces = " " * $depth
				$envMessage += "{0}{1}: {2}`r`n" -f $envValWithSpaces, $configSetting.Key, $envValue
			}
		}

    $envMessage
	}

  $buildFailed = $false

  try
  {
    PrintConsoleAppHeader
    InitializeBuild
    ResetDeployDirectory
    StartTranscript
    RegisterSourceControlProviders
    CreateLocalDropFolder
	  LoadBuildConfiguration
    CreateBuildDropFolder
    InvokeBuildScript
    InitializeSourceControlProvider
    WriteMergedConfiguration
    ValidateBuildPromotion

    Write-BuildSummaryMessage "Targeting $($powerdelivery.environment) environment with version $($powerdelivery.buildAppVersion) of $($powerdelivery.scriptName) deployment pipeline"

		InvokeBuildScriptBlock -condition $true -stage $powerdelivery.init -description "Initialization" -status "Initializing" -blockName "Init"
    InvokeBuildScriptBlock -condition ((($powerdelivery.environment -eq 'Commit') -and $powerdelivery.onServer) -or $powerdelivery.environment -eq 'Local') -stage $powerdelivery.compile -description "Compilations" -status "Compiling" -blockName "Compile"
	    
    $destDropLocation = $powerdelivery.dropLocation.TrimEnd('\')
    $destCurrentLocation = $powerdelivery.currentLocation.Path.TrimEnd('\')

		if ($powerdelivery.environment -ne "Local" -and $powerdelivery.environment -ne "Commit" -and $powerdelivery.onServer)
    {
      $PriorBuildDrop = $powerdelivery.priorBuild.DropLocation

      Write-BuildSummaryMessage "Copying prior build assets from $(Print-BuildPath $PriorBuildDrop) to $(Print-Buildpath $destDropLocation)"
      Copy-Robust $PriorBuildDrop $destDropLocation -recurse
		}

    $deployDir = $powerdelivery.deployDir

    Write-BuildSummaryMessage "Copying assets from $(Print-BuildPath $destDropLocation) to $(Print-BuildPath $deployDir)"
    Copy-Robust $destDropLocation $deployDir -recurse

	  Write-BuildSummaryMessage "Setting location to $(Print-BuildPath $deployDir)"
    Set-Location $deployDir

		InvokeBuildScriptBlock -condition ($powerdelivery.environment -eq 'Commit' -or $powerdelivery.environment -eq 'Local') -stage $powerdelivery.testUnits -description "Unit Tests" -status "Testing Units" -blockName "TestUnits"
	  InvokeBuildScriptBlock -condition $true -stage $powerdelivery.deploy -description "Deployments" -status "Deploying" -blockName "Deploy"
	  InvokeBuildScriptBlock -condition $true -stage $powerdelivery.testEnvironment -description "Environment Tests" -status "Testing Environment" -blockName "TestEnvironment"
	  InvokeBuildScriptBlock -condition ($Environment -eq 'Commit' -or $Environment -eq 'Local' -or $Environment -eq 'Test') -stage $powerdelivery.testAcceptance -description "Acceptance Tests" -status "Testing Acceptance" -blockName "TestAcceptance"
	  InvokeBuildScriptBlock -condition ($Environment -eq 'CapacityTest') -stage $powerdelivery.testCapacity -description "Capacity Tests" -status "Testing Capacity" -blockName "TestCapacity"
  }
  catch
  {
    $buildFailed = $true

		$ErrorRecord = $_[0]
    $Exception = $ErrorRecord.Exception

 		if ($Exception -ne $null)
		{
 			for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
			{
        #if (![String]::IsNullOrWhiteSpace($Exception.Message)) {
		    	#Write-Host $Exception.Message
      	#}

        if ($powerdelivery.isVerbose)
        {
          Write-Host $Exception.GetType().FullName

          if (![String]::IsNullOrWhiteSpace($Exception.StackTrace))
          {
            Write-Host $Exception.StackTrace
          }
        }
			}
		}

  	if (![String]::IsNullOrWhiteSpace($ErrorRecord.PSMessageDetails) -and $powerdelivery.isVerbose)
    {
  		Write-Host $ErrorRecord.PSMessageDetails
    }

    if (![String]::IsNullOrWhiteSpace($ErrorRecord.FullyQualifiedErrorId))
    {
    	Write-Host "ERROR: $($ErrorRecord.FullyQualifiedErrorId)" -ForegroundColor Red
    }

    if ($powerdelivery.isVerbose)
    {
      Write-Host $ErrorRecord.InvocationInfo.PositionMessage
      Write-Host $ErrorRecord.ScriptStackTrace
    }

		throw
  }
	finally
  {
    if (![String]::IsNullOrWhiteSpace($TranscriptFile))
    {
      if (Test-Path $TranscriptFile)
      {
		    Copy-Item -Force $TranscriptFile ($powerdelivery.dropLocation) | Out-Null
      }
      Stop-Transcript
    }

    $build_time = New-Timespan -Start ($powerdelivery.startedAtDate) -End (Get-Date)
    
    $build_time_string = ''

    $build_time_days = $build_time.Days
    if ($build_time_days -gt 0) {
      $build_time_string += "$build_time_days days"
    }

    $build_time_hours = $build_time.Hours
    if ($build_time_hours -gt 0) {
      if ($build_time_string.Length -gt 0) {
        $build_time_string += ' and '
      }
      $build_time_string += "$build_time_hours hours"
    }

    $build_time_minutes = $build_time.Minutes
    if ($build_time_minutes -gt 0) {
      if ($build_time_string.Length -gt 0) {
        $build_time_string += ' and '
      }
      $build_time_string += "$build_time_minutes minutes"
    }

    $build_time_seconds = $build_time.Seconds
    if ($build_time_seconds -gt 0) {
      if ($build_time_string.Length -gt 0) {
        $build_time_string += ' and '
      }
      $build_time_string += "$build_time_seconds seconds"
    }

    $build_time_ms = $build_time.Milliseconds
    if ($build_time_ms -gt 0) {
      if ($build_time_string.Length -gt 0) {
        $build_time_string += ' and '
      }
      $build_time_string += "$build_time_ms ms"
    }

    Start-BuildSummarySection 'Build Status'

    if ($buildFailed)
    {
      Write-BuildSummaryMessage "$product build failed in $build_time_string" -ForegroundColor Red
    }
    else
    {
      Write-BuildSummaryMessage "$product build succeeded in $build_time_string" -ForegroundColor Green
    }

    WriteBuildSummary

		Set-Location $curDir
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
function Init
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function Compile
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function Deploy
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function TestEnvironment
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function TestUnits
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function TestAcceptance
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function TestCapacity
{
	[CmdletBinding()]
	param(
    [Parameter(Position=0, Mandatory=1)][scriptblock] $action
  )
	
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
function Pipeline
{
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=1)][string] $scriptName,
		[Parameter(Mandatory=1)][string] $version
	)

	$powerdelivery.pipeline = $this
	$powerdelivery.buildAssemblyVersion = $version
	$powerdelivery.scriptName = $scriptName

	$buildAppVersion = "$appVersion"
	
  # TODO: Get version from source control provider here

  if ($powerdelivery.environment -ne 'local')
  {
  	if ($powerdelivery.onServer)
    {
    	$changeSetNumber = $powerdelivery.changeSet.Substring(1)
    	$buildAppVersion = "$($version).$($changeSetNumber)"
    }
    else
    {
      $changeSetNumber = "0"
      $buildAppVersion = "$($version).0"
    }
  }
  else
  {
		$buildAppVersion = $version
	}

  $powerdelivery.buildAppVersion = $buildAppVersion
}

Set-Alias Pow Invoke-Powerdelivery
Export-ModuleMember -Function Invoke-Powerdelivery -Alias Pow