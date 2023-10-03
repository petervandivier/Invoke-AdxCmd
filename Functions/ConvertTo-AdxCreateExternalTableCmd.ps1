
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

    if($CreateTableCmd -match '(?m)^\) with \($'){
        $CreateTableCmd = $CreateTableCmd.Replace(
            ') with (', 
            $ExternalTablePlaceholder
        )
    } else {
        $CreateTableCmd += "`n{ExternalTablePlaceholder}"
    }

    $PartitionByClause = $ExternalTableDataRow.Partitions.Name
    $PartitionByClause += ":datetime = "
    $PartitionByClause += "$($ExternalTableDataRow.Partitions.Function)".ToLower()
    $PartitionByClause += "($($ExternalTableDataRow.Partitions.ColumnName))"

    $ExternalTableDetails = ""
    $ExternalTableDetails += "kind = $($ExternalTableDataRow.TableType)`n"
    $ExternalTableDetails += "partition by ($PartitionByClause)`n"
    $ExternalTableDetails += "kind = $($ExternalTableDataRow.TableType)`n"
    $ExternalTableDetails += "dataformat = $($ExternalTableDataRow.Properties.Format.ToLower())`n"
    $ExternalTableDetails += "(`n"
    $ExternalTableDetails += "    h@'$($ExternalTableDataRow.ConnectionStrings)'"
    $ExternalTableDetails += ")`n"

    $CreateTableCmd = $CreateTableCmd.Replace(
        '{ExternalTablePlaceholder}',
        $ExternalTableDetails
    )

    return $CreateTableCmd
}
