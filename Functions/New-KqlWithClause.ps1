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
        if($Folder.Contains("\")){
            $Folder = "folder = @'$Folder'"
        } else {
            $Folder = "folder = '$Folder'"
        }
    }
    if($DocString){
        if($DocString.Contains("\")){
            $DocString = "docstring = @'$($DocString.Replace("'","''"))'"
        } else {
            $DocString = "docstring = '$($DocString.Replace("'","''"))'"
        }
    }
    if($Lookback){
        $Lookback = "lookback = time($($Lookback.ToString()))"
    }
    if($Folder -or $DocString -or $Lookback){
        $clause = ($Folder,$Lookback,$DocString | Where-Object {$_})  -join ",`n    "
        "with (`n    $clause`n)"
    }
}
