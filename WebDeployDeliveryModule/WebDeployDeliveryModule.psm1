function Initialize-WebDeployDeliveryModule {

	Register-DeliveryModuleHook 'PreDeploy' {
	
		$moduleConfig = Get-BuildConfig
		$webDeployments = $moduleConfig.WebDeploy

		if ($webDeployments) {
		
			Invoke-BuildConfigSections $webDeployments "Publish-WebDeploy"
		}
	}
}