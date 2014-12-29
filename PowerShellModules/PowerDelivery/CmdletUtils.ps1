function Require-NonNullField($variable, $errorMsg) {
  if ($variable -eq $null -or $variable -eq '') {
    throw $errorMsg;
  }
}

function Resolve-Error ($ErrorRecord=$Error[0]) {
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

function Print-BuildPath {
  [CmdletBinding()]
  param (
    [Parameter(Position=0,Mandatory=0)][string] $path
  )
  $pathUri = New-Object -TypeName System.Uri -ArgumentList $path
  if ($pathUri.IsUnc) {
    $path
  }
  else {
    Resolve-Path -Relative $path
  }
}