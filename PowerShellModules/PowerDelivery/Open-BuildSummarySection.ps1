function Open-BuildSummarySection {
  [CmdletBinding()]
  param([Parameter(Position=0,Mandatory=1)][string] $name)

  Close-BuildSummarySection
  
  $powerdelivery.summaryContent += @"
  <div class='panel panel-default'>
    <div class='panel-heading'>
      <h3 class='panel-title'>$name</h3>
    </div>
    <div class='panel-body' style='overflow-x: auto'>
      <ul class='list-group'>
"@
  $powerdelivery.isBuildSummarySectionStarted = $true

  $action = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)

  if ($name -ne 'Pipeline' -and $name -ne 'Build Status')
  {
    Write-Host "[$action] $name"
  }
}

Export-ModuleMember -Function Open-BuildSummarySection