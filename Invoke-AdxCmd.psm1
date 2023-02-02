
$packagesRoot = "$HOME\Desktop\microsoft.azure.kusto.tools.11.2.2\tools\net6.0"

[System.Reflection.Assembly]::LoadFrom("$packagesRoot\Kusto.Data.dll")

. $PsScriptRoot/Invoke-AdxCmd.ps1
