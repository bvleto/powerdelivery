function Initialize-SSISPackagesDeliveryModule {

	Register-DeliveryModuleHook 'PostDeploy' {
	
		$moduleConfig = Get-BuildConfig
		$ssisPackages = $moduleConfig.SSISPackages

		if ($ssisPackages) {
		
			Invoke-BuildConfigSections $ssisPackages "Invoke-SSIS"
		}
	}
}