
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
        $TablesDetails,

        [Parameter(
            Mandatory,
            ParameterSetName='Policies'
        )]
        $DatabasePolicies
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
        $DatabaseCachingPolicy = $DatabasePolicies.CachingPolicy | ConvertFrom-Json
        $TablesCachingPolicy = $TablesDetails.CachingPolicy | ConvertFrom-Json
        if(
            ($DatabaseCachingPolicy.DataHotSpan.Value -ne $TablesCachingPolicy.DataHotSpan) -or
            ($DatabaseCachingPolicy.IndexHotSpan.Value -ne $TablesCachingPolicy.IndexHotSpan)
        ){
            # https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/alter-table-cache-policy-command
            if($TablesCachingPolicy.DataHotSpan -eq $TablesCachingPolicy.IndexHotSpan){
                $CachingPolicy = ".alter table $TableName policy caching hot = timespan($($TablesCachingPolicy.DataHotSpan))"
            } else {
                $CachingPolicy = @(
                    ".alter table $TableName policy caching"
                    "    hotdata = timespan($($TablesCachingPolicy.DataHotSpan))"
                    "    hotindex = timespan($($TablesCachingPolicy.IndexHotSpan))"
                ) -join [Environment]::NewLine
            }

            $createCmd += [Environment]::NewLine * 2
            $createCmd += $CachingPolicy
        }

        $DatabaseRetentionPolicy = $DatabasePolicies.RetentionPolicy | ConvertFrom-Json
        $TablesRetentionPolicy =  $TablesDetails.RetentionPolicy | ConvertFrom-Json
        if(
            ($DatabaseRetentionPolicy.SoftDeletePeriod -ne $TablesRetentionPolicy.SoftDeletePeriod) -or
            ($DatabaseRetentionPolicy.Recoverability -ne $TablesRetentionPolicy.Recoverability)
        ){
            # https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/alter-table-retention-policy-command
            $RetentionPolicy = @(
                ".alter table $TableName policy retention"
                '```'
                [PsCustomObject]@{
                    SoftDeletePeriod = $TablesRetentionPolicy.SoftDeletePeriod
                    Recoverability = $TablesRetentionPolicy.Recoverability
                } | ConvertTo-Json
                '```'
            ) -join [Environment]::NewLine 

            $createCmd += [Environment]::NewLine * 2
            $createCmd += $RetentionPolicy
        }
    }

    return $createCmd
}
