
function Invoke-AdxCmd {
<#
.SYNOPSIS
    Send a KQL string to an Azure Data Explorer cluster

.DESCRIPTION
    Humble homage to dataplat/Invoke-SqlCmd2

.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/api/powershell/powershell
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $clusterUrl,

        [Parameter()]
        [string]
        $databaseName,

        [Parameter()]
        [Alias('Query')]
        [string]
        $Command
    )

    $kcsb = New-Object Kusto.Data.KustoConnectionStringBuilder ($clusterUrl, $databaseName)

    $queryProvider = [Kusto.Data.Net.Client.KustoClientFactory]::CreateCslQueryProvider($kcsb)

    $crp = New-Object Kusto.Data.Common.ClientRequestProperties

    $crp.ClientRequestId = "PowerShell.Invoke-AdxCmd;" + [Guid]::NewGuid().ToString()

    $crp.SetOption([Kusto.Data.Common.ClientRequestProperties]::OptionServerTimeout, [TimeSpan]::FromSeconds(30))

    $reader = $queryProvider.ExecuteQuery($Command, $crp)

    $dataTable = [Kusto.Cloud.Platform.Data.ExtendedDataReader]::ToDataSet($reader).Tables[0]

    $dataView = New-Object System.Data.DataView($dataTable)

    $dataView
}
