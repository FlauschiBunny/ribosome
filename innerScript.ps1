[CmdletBinding()]
param (
    [Parameter()]
    [object]
    $ParameterName
)
$ParameterName | Get-Member

$ParameterName
