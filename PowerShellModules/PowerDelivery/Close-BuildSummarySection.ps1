function Close-BuildSummarySection {
  [CmdletBinding()]
  param()
  if ($powerdelivery.isBuildSummarySectionStarted) {
    $powerdelivery.summaryContent += '</ul></div></div>'
    $powerdelivery.isBuildSummarySectionStarted = $false
  }
}

Export-ModuleMember -Function Close-BuildSummarySection