function Copy-Robust {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string] $path,
	    [Parameter(Position=1,Mandatory=1)][string] $destination,
	    [Parameter(Position=2,Mandatory=0)][string] $filter	= "*.*",
        [Parameter(Position=3,Mandatory=0)][switch] $recurse = $false,
        [Parameter(Position=4,Mandatory=0)][switch] $excludeNewer = $false,
        [Parameter(Position=5,Mandatory=0)][switch] $excludeOlder = $false
    )

    mkdir -Force -ErrorAction SilentlyContinue $destination | Out-Null

    $command = "robocopy `"$path`" `"$destination`" $filter /E /NP /NJH /NJS /NFL /NDL"

    $msg = "$path -> $destination"

    if ($recurse -eq $false) {
        $command += " /LEV:1"
        $msg += " recursively"
    }

    if ($excludeNewer) {
        $command += " /XN"
        $msg += " excluding newer files"
    }

    if ($excludeOlder) {
        $command += " /XO"
        if ($excludeNewer) {
            $msg += " and"
        }
        $msg += " excluding older files"
    }

    Write-BuildSummaryMessage $msg

    Invoke-Expression $command
            
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed to copy one or more files."
    }
}

Export-ModuleMember -Function Copy-Robust