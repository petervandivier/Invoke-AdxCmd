
function Deploy-AdxObject {
    Param(
        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]
        $FilePath,

        [Parameter(Mandatory)]
        [ValidateScript({$_.EndsWith(';Fed=True')})]
        [string]
        $ClusterUrl,

        [Parameter(Mandatory)]
        [string]
        $DatabaseName,

        [Parameter()]
        [switch]
        $ContinueOnErrors
    )

    $Command = Get-Content $FilePath -Raw

    # also matches `.create-merge`, `.create-or-alter`, etc...
    $FirstControlWord = ([char[]]($Command -replace "[\s\n\r]"))[0 .. 6] -join ''

    $IsMultiBatch = $Command -match '\r\n\r\n'
    if($IsMultiBatch){
        Write-Verbose "More than one batch detected in deployment script. Commands will be wrapped in an `.execute` block."
        $Command = ".execute database script with (ContinueOnErrors=$ContinueOnErrors) <| `n$Command"
    }

    if('.create' -eq $FirstControlWord){
        Invoke-AdxCmd -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName -Command $Command
    } else {
        Write-Error "First control word in file '$FilePath' is '$FirstControlWord'. ``Deploy-AdxObject`` should only be used to create object. "
    }
}
