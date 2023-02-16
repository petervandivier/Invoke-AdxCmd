
function Invoke-AdxCmd {
<#
.SYNOPSIS
    Send a KQL string to an Azure Data Explorer cluster

.DESCRIPTION
    Humble homage to dataplat/Invoke-SqlCmd2

.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/api/powershell/powershell

.PARAMETER ClusterUrl
    URL/URI you get back from `Get-AzKustoCluster | Select Uri`. Should include the `;Fed=True` suffix
    See also: https://learn.microsoft.com/en-us/azure/data-explorer/kusto/api/connection-strings/kusto

.PARAMETER DatabaseName
    May be blank. Establishes the connection context to the database if it exists. 

.PARAMETER Command
    The KQL string to execute

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({$_.EndsWith(';Fed=True')})]
        [string]
        $ClusterUrl,

        [Parameter()]
        [string]
        $DatabaseName,

        [Parameter(Mandatory)]
        [Alias('Query')]
        [string]
        $Command
    )

    $kcsb = New-Object Kusto.Data.KustoConnectionStringBuilder ($clusterUrl, $databaseName)

    $queryProvider = [Kusto.Data.Net.Client.KustoClientFactory]::CreateCslQueryProvider($kcsb)

    $crp = New-Object Kusto.Data.Common.ClientRequestProperties

    $crp.ClientRequestId = "PowerShell.Invoke-AdxCmd;" + [Guid]::NewGuid().ToString()

    $crp.SetOption([Kusto.Data.Common.ClientRequestProperties]::OptionServerTimeout, [TimeSpan]::FromSeconds(30))

    $isControlCmd = ('.' -eq ([char[]]($Command -replace "[\s\n\r]"))[0])

    $reader = if($isControlCmd){
        # n.b. `.show` may submit as either a control command or a query 
        $queryProvider.ExecuteControlCommand($Command, $crp)
    } else {
        $queryProvider.ExecuteQuery($Command, $crp)
    } 

    $dataTable = [Kusto.Cloud.Platform.Data.ExtendedDataReader]::ToDataSet($reader).Tables[0]

    $dataView = New-Object System.Data.DataView($dataTable)

    $dataView
}
