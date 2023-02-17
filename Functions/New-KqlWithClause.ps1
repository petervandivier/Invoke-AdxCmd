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
        "with (`n    $($Folder,$DocString -join ",`n    ")`n)"
    }
}
