#Requires -PSEdition Core

function Export-AdxTableData {
<#
.DESCRIPTION
    Requires PS Core for Export-Csv w/o -NoTypeInfo flag
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
        [string]
        $TableName,

        [string]
        $FilePath
    )

    if(-not $FilePath){
        $FilePath = "$TableName.csv"
    }

    $DatabaseTables = Invoke-AdxCmd -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName ".show tables details"

    $TableDetails = $DatabaseTables | Where-Object TableName -eq $TableName

    if($null -eq $TableDetails){
        Write-Error "No table named '$TableName' found in database '$DatabaseName' for cluster '$ClusterUrl'. "
        return
    }

    $NeedsRowcountLimit = $false
    $RowCountToExport = $TableDetails.TotalRowCount

    if($RowCountToExport -gt 500000){
        Write-Warning "Table '$TableName' has '$($TableDetails.TotalRowCount)' rows which exceeds the maximum allowed of 500,000. Not all data will be exported. See https://aka.ms/kustoquerylimits for more information. "
        $RowCountToExport = 500000
        $NeedsRowcountLimit = $true
    }

    $AvgBytesPerRow = $TableDetails.TotalOriginalSize / $TableDetails.TotalRowCount

    [int]$EstimatedMaxPossibleRows = 64mb / $AvgBytesPerRow

    if($RowCountToExport -gt $EstimatedMaxPossibleRows){
        Write-Warning "Estimated size-of-data for '$RowCountToExport' rows from table '$TableName' is '$([math]::Round($RowCountToExport * $AvgBytesPerRow / 1mb, 2))' mb. Max possible export size is 64mb. See https://aka.ms/kustoquerylimits for more information. "
        $OneThousandRowsSizeBytes = (Invoke-AdxCmd -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName "$TableName | take 1000 | summarize OneThousandRowsSizeBytes = sum(estimate_data_size(*))").OneThousandRowsSizeBytes
        # buffer 5% under est. max 
        $RowCountToExport = [math]::Round(950 * (64mb / $OneThousandRowsSizeBytes))
        $NeedsRowcountLimit = $true
    }

    $Query = "$TableName"
    if($NeedsRowcountLimit){
        Write-Warning "RowCount limited to '$RowCountToExport' " 
        $Query = "$Query | limit $RowCountToExport"
    }

    Write-Verbose "'$([math]::Round($RowCountToExport * $AvgBytesPerRow / 1mb,2))' mb expected size-of-data for '$RowCountToExport' rows at '$([math]::Round($AvgBytesPerRow,2))' bytes per row. "

    $Data = Invoke-AdxCmd -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName -Query $Query

    $Data | Export-Csv -UseQuotes AsNeeded -Path $FilePath
}