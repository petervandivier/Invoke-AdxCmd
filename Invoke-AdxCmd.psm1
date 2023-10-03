#Requires -PsEdition Core

Push-Location $PsScriptRoot

$packagesRoot = "$HOME\.dotnet\microsoft.azure.kusto.tools.11.2.2\tools\net6.0"

[System.Reflection.Assembly]::LoadFrom("$packagesRoot\Kusto.Data.dll")

Get-ChildItem Classes -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}

. ./Invoke-AdxCmd.ps1

Export-ModuleMember 'Invoke-AdxCmd'

Get-ChildItem Functions -Filter *.ps1 | ForEach-Object {
    . $_.FullName
    Export-ModuleMember $_.BaseName
}

Import-Csv "Assets/KqlKeywords.csv"
| Where-Object IsReserved -eq 'TRUE'
| Select-Object -ExpandProperty Word
| Set-Variable -Name KqlReservedKeywords -Option ReadOnly -Force

Export-ModuleMember -Variable KqlReservedKeywords

Pop-Location
