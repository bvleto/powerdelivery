﻿<#
.Synopsis
Creates a local Windows user account on a computer.

.Description
Creates a local Windows user account on a computer.

.Parameter userName
The username of the account to create.

.Parameter password
The password of the account to create.

.Parameter computerName
Optional. The computer to be modified.

.Example
Add-WindowsUserToGroup -userName 'DOMAIN\MyUser' `
					   -password 's@m3p@ss' `
					   -computerName MYCOMPUTER
#>
function New-WindowsUserAccount {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)] $userName,
		[Parameter(Position=1,Mandatory=1)] $password,
		[Parameter(Position=2,Mandatory=0)] $computerName
	)
	
	Set-Location $powerdelivery.deployDir

  $computerNames = $computerName -split "," | % { $_.Trim() }

  foreach ($curComputerName in $computerNames) {

      $invokeArgs = @{
        "ComputerName" = $curComputerName;
        "ArgumentList" = @($curComputerName, $userName, $password);
        "ScriptBlock" = {
          param($curComputerName, $userName, $password)

          if ($curComputerName -eq 'localhost' -or ([String]::IsNullOrWhitespace($curComputerName))) {
            $curComputerName = $env:computername
          }

          $localUsersSet = [ADSI]"WinNT://$curComputerName/Users"
          $localUsers = @($localUsersSet.psbase.Invoke("Members")) 

          $foundAccount = $false

          $localUsers | foreach {
            if ($_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) -eq $userName) {
              $foundAccount = $true
            }
          }

          if (!$foundAccount) {

            $addUserArgs = @(
              "user",
              $userName,
              $password,
              "/add",
              "/active:YES",
              "/expires:NEVER",
              "/FullName:`"$userName`""
            )

            $addUserProcess = Start-Process -FilePath "C:\Windows\System32\net.exe" -ArgumentList $addUserArgs -PassThru -Wait
            $addUserProcess.WaitForExit()

            "$logPrefix User $userName created on $curComputerName successfully."
          }    
        }; 
        "ErrorAction" = "Stop"
      }

      $msg = "$userName"

      if ([String]::IsNullOrWhitespace($curComputerName) -or ($curComputerName -eq 'localhost')) {
        $invokeArgs.Remove("ComputerName")
      }
      else {
        $msg += " ($curComputerName)"
      }

      Invoke-Command @invokeArgs

      Write-BuildSummaryMessage $msg
    }
}

Export-ModuleMember -Function New-WindowsUserAccount