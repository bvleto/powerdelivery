function Initialize-RoundhouseDeliveryModule {

	Register-DeliveryModuleHook 'PostDeploy' {
	
		$moduleConfig = Get-BuildConfig
		$roundhouseDatabases = $moduleConfig.Roundhouse

		if ($roundhouseDatabases) {
		
			Invoke-BuildConfigSections $roundhouseDatabases "Invoke-Roundhouse"
		}
	}
}