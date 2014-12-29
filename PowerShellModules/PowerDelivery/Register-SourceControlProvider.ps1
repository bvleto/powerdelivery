function Register-SourceControlProvider($sourceControlProviderName) {
  if ($powerdelivery.sourceControlProviders[$sourceControlProviderName] -ne $null) {
    throw "Source control provider $sourceControlProviderName is already registered."
  }
  $powerdelivery.sourceControlProviders += $sourceControlProviderName
}

Export-ModuleMember -Function Register-SourceControlProvider