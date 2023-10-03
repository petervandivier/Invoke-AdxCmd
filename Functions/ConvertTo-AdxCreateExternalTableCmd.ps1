
function ConvertTo-AdxCreateExternalTableCmd {
<#
.Link
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/external-tables-azurestorage-azuredatalake
#>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            Mandatory
        )]
        [AdxTableCslSchemaDatarow]
        $CslSchemaDataRow,

        [Parameter(
            Position = 1,
            ValueFromPipeline,
            Mandatory
        )]
        [AdxExternalTableDataRow]
        $ExternalTableDataRow
    )
    $CreateTableCmd = ConvertTo-AdxCreateTableCmd $CslSchemaDataRow
    $CreateTableCmd = $CreateTableCmd.Replace(
        '.create-merge table',
        '.create external table'
    )

    $ExternalTablePlaceholder = @(
        ')'
        '{ExternalTablePlaceholder}'
        'with ('
    ) -join "`n"

    [bool]$HasWithClause = $CreateTableCmd -match '(?m)^\) with \($'

    if($HasWithClause){
        $CreateTableCmd = $CreateTableCmd.Replace(
            ') with (', 
            $ExternalTablePlaceholder
        )
    } else {
        $CreateTableCmd += "`n{ExternalTablePlaceholder}"
    }

    $PartitionByClause = ""
    if(0 -lt $ExternalTableDataRow.Partitions.Count){
        $PartitionByClause += $ExternalTableDataRow.Partitions.Name
        $PartitionByClause += ":datetime = "
        $PartitionByClause += "$($ExternalTableDataRow.Partitions.Function)".ToLower()
        $PartitionByClause += "($($ExternalTableDataRow.Partitions.ColumnName))"
    }

    $ExternalTableDetails = ""
    $ExternalTableDetails += "kind = $($ExternalTableDataRow.TableType.ToLower())`n"
    if(-not [string]::IsNullOrWhiteSpace($PartitionByClause)){
        $ExternalTableDetails += "partition by ($PartitionByClause)`n"
    }
    if(-not [string]::IsNullOrWhiteSpace($ExternalTableDataRow.PathFormat)){
        $ExternalTableDetails += "pathformat = ($($ExternalTableDataRow.PathFormat))`n"
    }
    $ExternalTableDetails += "dataformat = $($ExternalTableDataRow.Properties.Format.ToLower())`n"
    $ExternalTableDetails += "(`n"
    $ExternalTableDetails += "    h@'$($ExternalTableDataRow.ConnectionStrings)'`n"
    $ExternalTableDetails += ")`n"

    $CreateTableCmd = $CreateTableCmd.Replace(
        '{ExternalTablePlaceholder}',
        $ExternalTableDetails
    )

    if($ExternalTableDataRow.Properties.Compressed){
        if($HasWithClause){
            $CreateTableCmd = $CreateTableCmd.Replace(
                'with (',
                "with (`n    compressed = true,"
            )
        } else {
            $CreateTableCmd += "with ( compressed = true )"
        }
    }

    return $CreateTableCmd
}
