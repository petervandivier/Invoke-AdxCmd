function New-KqlWithClause {
<#
.PARAMETER Lookback
    Lookback type cannot be declared since KQL allows for nullable [timespan] while PowerShell does not
#>
    Param(
        [string]$Folder,
        [string]$DocString,
        $Lookback
    )
    if($Folder){
        $Folder = "folder = '$Folder'"
    }
    if($DocString){
        $DocString = "docstring = '$($DocString.Replace("'","''"))'"
    }
    if($Lookback){
        $Lookback = "lookback = time($($Lookback.ToString()))"
    }
    if($Folder -or $DocString -or $Lookback){
        $clause = ($Folder,$Lookback,$DocString | Where-Object {$_})  -join ",`n    "
        "with (`n    $clause`n)"
    }
}
