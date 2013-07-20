function Initialize-WebDeployDeliveryModule {

	Register-DeliveryModuleHook 'PreDeploy' {
	
		$moduleConfig = Get-BuildModuleConfig
		$webDeployments = $moduleConfig.WebDeploy

		if ($webDeployments) {
		
			Invoke-ConfigSections $webDeployments "Publish-WebDeploy"
		}
	}
}