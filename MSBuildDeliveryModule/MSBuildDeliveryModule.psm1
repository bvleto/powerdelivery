function Initialize-MSBuildDeliveryModule {

	Register-DeliveryModuleHook 'PreCompile' {
	
		$moduleConfig = Get-BuildConfig
		$msBuildProjects = $moduleConfig.MSBuild
		
		$currentDirectory = Get-Location

		if ($msBuildProjects) {
			
			$msBuildProjects.Keys | % {
				$invokeArgs = @{}
				
				$project = $msBuildProjects[$_]
				
				Invoke-BuildConfigSection $project "Invoke-MSBuild"	
				
				Set-Location $currentDirectory
			}
		}
	}
}
