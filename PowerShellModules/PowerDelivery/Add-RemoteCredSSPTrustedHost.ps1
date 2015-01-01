function Add-RemoteCredSSPTrustedHost {
    param(
        [Parameter(Position=0,Mandatory=1)] [string] $clientComputerName,
        [Parameter(Position=1,Mandatory=1)] [string] $serverComputerName
    )

    Write-BuildSummaryMessage "Enabling $serverComputerName to receive remote CredSSP credentials"

    Invoke-Command -ComputerName $serverComputerName -ScriptBlock {
        Enable-WSManCredSSP -Role Server -Force | Out-Null
    }

    $result = Invoke-Command -ComputerName $clientComputerName `
        -ArgumentList @($serverComputerName) `
        -ScriptBlock { 
            param($varServerComputerName)

            $credSSP = Get-WSManCredSSP

            $computerExists = $false

            if ($credSSP -ne $null) {
                if ($credSSP.length -gt 0) {
                    $trustedClients = $credSSP[0].Substring($credSSP[0].IndexOf(":") + 2)
                    $trustedClientsList = $trustedClients -split "," | % { $_.Trim() }
            
                    if ($trustedClientsList.Contains("wsman/$varServerComputerName")) {
                        $computerExists = $true
                    }
                }
            }

            if (!$computerExists) {
                Enable-WSManCredSSP -Role Client -DelegateComputer "$varServerComputerName" -Force | Out-Null
                return true
            }
            else {
                return false
            }
        }

    if ($result) {
        Write-BuildSummaryMessage "Enabling CredSSP credentials to travel from $clientComputerName to $serverComputerName"
    }
}

Export-ModuleMember -Function Add-RemoteCredSSPTrustedHost