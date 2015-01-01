function Add-CredSSPTrustedHost {
    param(
        [Parameter(Position=0,Mandatory=1)] [string] $computerName
    )

    Write-BuildSummaryMessage "Enabling $computerName to receive remote CredSSP credentials"

    Invoke-Command -ComputerName $computerName -ScriptBlock {
        Enable-WSManCredSSP -Role Server -Force | Out-Null
    }

    $credSSP = Get-WSManCredSSP

    $computerExists = $false

    if ($credSSP -ne $null) {
        if ($credSSP.length -gt 0) {
            $trustedClients = $credSSP[0].Substring($credSSP[0].IndexOf(":") + 2)
            $trustedClientsList = $trustedClients -split "," | % { $_.Trim() }
            
            if ($trustedClientsList.Contains("wsman/$computerName")) {
                $computerExists = $true
            }
        }
    }

    if (!$computerExists) {
        Write-BuildSummaryMessage "Enabling CredSSP credentials to travel from $($env:COMPUTERNAME) to $computerName"
        Enable-WSManCredSSP -Role Client -DelegateComputer $computerName -Force | Out-Null
    }
}

Export-ModuleMember -Function Add-CredSSPTrustedHost