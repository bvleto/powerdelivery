<#
.Synopsis
Adds an existing Windows user account on a computer to a specific Windows security group.

.Description
Adds an existing Windows user account on a computer to a specific Windows security group.

.Parameter userName
The username of the account to add to the group.

.Parameter groupName
The name of the group to add the user to.

.Parameter computerName
The computer to be modified.

.Example
Add-WindowsUserToGroup -userName 'DOMAIN\MyUser' `
					   -groupName 'Performance Monitor Users' `
					   -computerName MYCOMPUTER
#>
function Add-WindowsUserToGroup {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)] $userName,
		[Parameter(Position=1,Mandatory=1)] $groupName,
		[Parameter(Position=2,Mandatory=1)] $computerName
	)
	
  $computerNames = $computerName -split "," | % { $_.Trim() }

  foreach ($curComputerName in $computerNames) {

    $invokeArgs = @{
      "ComputerName" = $curComputerName;
      "ArgumentList" = @($curComputerName, $groupName, $userName);
      "ScriptBlock" = {
        param($curComputerName, $groupName, $userName)

        $group = [ADSI]"WinNT://$curComputerName/$groupName,group"
        $usersSet = [ADSI]"WinNT://$curComputerName/$groupName"
        $users = @($usersSet.psbase.Invoke("Members")) 

        $foundAccount = $false

        $users | foreach {
          if ($_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) -eq $userName) {
            $foundAccount = $true
          }
        }

        if (!$foundAccount) {
          $group.psbase.Invoke("Add", ([ADSI]"WinNT://$userName").path)
          return true
        }
        else {
          return false
        }
      };
      "ErrorAction" = "Stop"
    }

    if ([String]::IsNullOrWhitespace($curComputerName) -or ($curComputerName -eq 'localhost')) {
      $invokeArgs.Remove("ComputerName")
    }

    $result = Invoke-Command @invokeArgs
    if ($result) {
      Write-BuildSummaryMessage "Adding $userName user to $groupName group on $curComputerName..."
    }
  }
}

Export-ModuleMember -Function Add-WindowsUserToGroup