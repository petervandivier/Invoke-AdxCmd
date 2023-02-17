function New-KqlWithClause {
    Param(
        [string]$Folder,
        [string]$DocString
    )
    if($Folder){
        $Folder = "folder = '$Folder'"
    }
    if($DocString){
        $DocString = "docstring = '$($DocString.Replace("'","''"))'"
    }
    if($Folder -or $DocString){
        $clause = ($Folder,$DocString | Where-Object {$_})  -join ",`n    "
        "with (`n    $clause`n)"
    }
}
