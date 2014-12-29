<#
.Synopsis
Writes a message to the PowerDelivery HTML build summary page (YourBuild.html in the PowerDelivery\Deploy dir).

.Description
Writes a message to the PowerDelivery HTML build summary page.

.Parameter command
The PowerShell command that sent the message.

.Parameter message
The message to add to the build summary.

.Example
Write-BuildSummaryMessage 'My-Cmdlet' 'Something important happened!'
#>
function Write-BuildSummaryMessage {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string] $message,
        [Parameter(Position=1,Mandatory=0)] $foregroundColor = $null
    )

    $action = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)

    $actionText = $action

    if ($powerdelivery.lastAction -eq $action)
    {
        $actionText = ''
    }

    $powerdelivery.summaryContent += @"
    <li class='list-group-item'>
        <div class='row'>
            <div class='col-sm-3' style='font-size: 12px'>$actionText</div>
            <div class='col-sm-9'>$message</div>
        </div>
    </li>
"@

    $invokeArgs = @{'Object' = "[$action] $message"}

    if ($foregroundColor -ne $null) {
        $invokeArgs.Add('ForegroundColor', $foregroundColor)
    }

    Write-Host @invokeArgs

    $powerdelivery.lastAction = $action
}

Export-ModuleMember -Function Write-BuildSummaryMessage