﻿function Add-CredSSPTrustedHost {
    param(
        [Parameter(Position=0,Mandatory=1)] [string] $computerName
    )

    $logPrefix = "Add-CredSSPTrustedHost:"

    Invoke-Command -ComputerName $computerName -ArgumentList @($logPrefix) -ScriptBlock {
        param($varLogPrefix)
        Write-Host "$varLogPrefix Enabling $($env:COMPUTERNAME) to receive remote CredSSP credentials"
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
        "$logPrefix Enabling CredSSP credentials to travel from $($env:COMPUTERNAME) to $computerName"
        Enable-WSManCredSSP -Role Client -DelegateComputer $computerName -Force | Out-Null
    }
}

Export-ModuleMember -Function Add-CredSSPTrustedHost