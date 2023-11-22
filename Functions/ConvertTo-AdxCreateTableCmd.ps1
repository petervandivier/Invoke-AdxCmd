
function ConvertTo-AdxCreateTableCmd {
<#
.Synopsis
    Returns a valid `.create table` command from DB-supplied `cslschema` input

.Description
    Does not make any database calls. Takes input well-formed from a prior database
    call (or mocked to match) and formats it to valid KQL DDL.

    Suffix Retention & Caching policy statements as needed. That is: if-and-only-if
    table-level policies differ from database defaults. For this however, we must
    require that database defaults be supplied.

.Parameter CslSchemaDataRow
    Incoming column names from `.show database cslschema` are already quoted as needed.
    Table names from the same input are _not_ likewise quotenamed and must be processed
    through `Format-KqlIdentifier`
#>
    [CmdletBinding(DefaultParameterSetName='Schema')]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            Mandatory,
            ParameterSetName='Schema'
        )]
        [Parameter(
            ValueFromPipeline,
            Mandatory,
            ParameterSetName='Policies'
        )]
        [AdxTableCslSchemaDatarow]
        $CslSchemaDataRow,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        $TablePolicy,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        $DatabasePolicy,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        [AllowNull()]
        $UpdatePolicy,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        [Alias('RlsPolicy')]
        [AllowNull()]
        $RowLevelSecurityPolicy,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        [AllowNull()]
        $PartitionPolicy,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        [AllowNull()]
        $ContinuousExport
    )
    $createStub = ".create-merge table {TableName} (`n{ColumnList}`n) {WithClause}"
    $TableName = $CslSchemaDataRow.TableName | Format-KqlIdentifier

    $WithClause = New-KqlWithClause $CslSchemaDataRow.Folder $CslSchemaDataRow.DocString
    $ColumnList = ($CslSchemaDataRow.Schema.Split(',') | ForEach-Object {
        "    $($_.Replace(':', ': '))"
    }) -join ",$([Environment]::NewLine)"
    $createCmd = $createStub.Replace(
        '{TableName}', $TableName
    ).Replace(
        '{ColumnList}', $ColumnList
    ).Replace(
        '{WithClause}', $WithClause
    )

    if($PsCmdlet.ParameterSetName -eq 'Policies'){
#region cache
        $DatabaseCachingPolicy = $DatabasePolicy.CachingPolicy | ConvertFrom-Json
        $TablesCachingPolicy = $TablePolicy.CachingPolicy | ConvertFrom-Json
        if(
            ($DatabaseCachingPolicy.DataHotSpan.Value -ne $TablesCachingPolicy.DataHotSpan) -or
            ($DatabaseCachingPolicy.IndexHotSpan.Value -ne $TablesCachingPolicy.IndexHotSpan)
        ){
            # https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/alter-table-cache-policy-command
            if($TablesCachingPolicy.DataHotSpan -eq $TablesCachingPolicy.IndexHotSpan){
                $CachingPolicyCmd = ".alter table $TableName policy caching hot = timespan($($TablesCachingPolicy.DataHotSpan))"
            } else {
                $CachingPolicyCmd = @(
                    ".alter table $TableName policy caching"
                    "    hotdata = timespan($($TablesCachingPolicy.DataHotSpan))"
                    "    hotindex = timespan($($TablesCachingPolicy.IndexHotSpan))"
                ) -join [Environment]::NewLine
            }

            $createCmd += [Environment]::NewLine * 2
            $createCmd += $CachingPolicyCmd
        }
#endregion cache

#region retention
        $DatabaseRetentionPolicy = $DatabasePolicy.RetentionPolicy | ConvertFrom-Json
        $TablesRetentionPolicy =  $TablePolicy.RetentionPolicy | ConvertFrom-Json
        if(
            ($DatabaseRetentionPolicy.SoftDeletePeriod -ne $TablesRetentionPolicy.SoftDeletePeriod) -or
            ($DatabaseRetentionPolicy.Recoverability -ne $TablesRetentionPolicy.Recoverability)
        ){
            # https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/alter-table-retention-policy-command
            $RetentionPolicyCmd = @(
                ".alter table $TableName policy retention"
                '```'
                [PsCustomObject]@{
                    SoftDeletePeriod = $TablesRetentionPolicy.SoftDeletePeriod
                    Recoverability = $TablesRetentionPolicy.Recoverability
                } | ConvertTo-Json
                '```'
            ) -join [Environment]::NewLine 

            $createCmd += [Environment]::NewLine * 2
            $createCmd += $RetentionPolicyCmd
        }
#endregion retention

#region update
        if($null -ne $UpdatePolicy){
            $UpdatePolicyJson = ConvertTo-Json -InputObject ([array][PsCustomObject]@{
                IsEnabled       = [bool]($UpdatePolicy.IsEnabled)
                Source          = $UpdatePolicy.Source
                Query           = $UpdatePolicy.Query
                IsTransactional = [bool]($UpdatePolicy.IsTransactional)
                PropagateIngestionProperties = [bool]($UpdatePolicy.PropagateIngestionProperties)
            })
            $UpdatePolicyCmd = @(
                ".alter table $TableName policy update"
                '```'
                $UpdatePolicyJson
                '```'
            ) -join [Environment]::NewLine 

            $createCmd += [Environment]::NewLine * 2
            $createCmd += $UpdatePolicyCmd
        }
#endregion update

#region row_level_security
        if($null -ne $RowLevelSecurityPolicy){
            if($RowLevelSecurityPolicy.IsEnabled){
                $RlsQuery = "$($RowLevelSecurityPolicy.Query)".Trim()
                $RowLevelSecurityPolicyCmd = ".alter table $TableName policy row_level_security enable `"$RlsQuery`""

                $createCmd += [Environment]::NewLine * 2
                $createCmd += $RowLevelSecurityPolicyCmd
            }
        }
#endregion row_level_security

#region partition_policy
if($null -ne $PartitionPolicy){
    $PartitionPolicyObject = ($PartitionPolicy.Policy | ConvertFrom-Json) | Select-Object PartitionKeys
    if(1 -eq $PartitionPolicyObject.PartitionKeys.Properties.Seed){
        $PartitionPolicyObject.PartitionKeys.Properties.PSObject.Properties.Remove('Seed')
    }
    if("Default" -eq $PartitionPolicyObject.PartitionKeys.Properties.PartitionAssignmentMode){
        $PartitionPolicyObject.PartitionKeys.Properties.PSObject.Properties.Remove('PartitionAssignmentMode')
    }
    $PartitionDefinition = @(
        '```'
        $PartitionPolicyObject | ConvertTo-Json -Depth 3
        '```'
    ) -join "`n"
    $RowLevelSecurityPolicyCmd = ".alter table $TableName policy partitioning`n$PartitionDefinition"

    $createCmd += [Environment]::NewLine * 2
    $createCmd += $RowLevelSecurityPolicyCmd
}
#endregion partition_policy

#region continuous_export
        if($null -ne $ContinuousExport){
            <#
                .Link
                    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/data-export/create-alter-continuous
                .Link
                    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/data-export/show-continuous-export
                .Link
                    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/data-export/continuous-export-with-managed-identity?tabs=user-assigned%2Cazure-storage#3---create-a-continuous-export-job
            #>
            # TODO: support managed identities (needs additional data not found in `.show continuous exports`)

            # .CursorScopedTables is an array of identifier-quoted DB+Table names
            # currently parsed in parent Export-* command control query
            # TODO: are multiple tables even supported here?
            # TODO: are cross-database references supported here?
            $CursorScopedTable0 = $ContinuousExport.Table0 

            $ContinuousExportWithClause = @()
            if($ContinuousExport.ForcedLatency -ne [timespan]"00:00:00"){
                $ContinuousExportWithClause += "    forcedLatency = $($ContinuousExport.ForcedLatency)"
            }
            if($ContinuousExport.IntervalBetweenRuns -ne [timespan]"00:00:00"){
                $ContinuousExportWithClause += "    intervalBetweenRuns = `"$($ContinuousExport.IntervalBetweenRuns)`""
            }

            $ContinuousExportProperties = $ContinuousExport.ExportProperties | ConvertFrom-Json
            if($ContinuousExportProperties.SizeLimit -ne 100mb){
                $ContinuousExportWithClause += "    sizeLimit = $($ContinuousExportProperties.SizeLimit)"
            }
            if($ContinuousExportProperties.isDisabled){
                $ContinuousExportWithClause += "    isDisabled = true"
            }
            # unsure what to do with these properties at this time
            #     - WriteNativeParquetV2
            #     - ParquetDatetimePrecision
            #     - ReportDeltaLogResults

            $ContinuousExportWithClause = $ContinuousExportWithClause -join ",`n"

            $ContinuousExportCmd =  ".create-or-alter continuous-export $($ContinuousExport.Name)`n"
            $ContinuousExportCmd += "    over ($($CursorScopedTable0))`n"
            $ContinuousExportCmd += "    to table $($ContinuousExport.ExternalTableName)`n"
            if($null -ne $ContinuousExportWithClause){
                $ContinuousExportCmd += "with (`n"
                $ContinuousExportCmd += $ContinuousExportWithClause
                $ContinuousExportCmd += "`n) "
            }
            $ContinuousExportCmd += "<| $($ContinuousExport.Query)"

            $createCmd += [Environment]::NewLine * 2
            $createCmd += $ContinuousExportCmd
        }
#endregion continuous_export
    }

    return $createCmd
}
