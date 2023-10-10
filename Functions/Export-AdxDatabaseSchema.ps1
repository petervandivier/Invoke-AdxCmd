
function Export-AdxDatabaseSchema {
<#
.Synopsis
    `pg_dump --schema-only` for Azure Data Explorer.

.Description
    Given a cluster URL & Database name (and sufficient permissions for the running user),
    extracts most objects in a database and exports them to discrete .KQL scripts in a 
    directory tree relative to your current working directory.

    Currently supported object types:
        - Tables
            - Row Level Security Policy
            - Update Policy
            - Retention Policy
            - Caching Policy
        - Functions
        - Materialized Views

    Currently unsupported types:
        - External Tables
#>
    param (
        [Parameter(Mandatory)]
        [ValidateScript({$_.EndsWith(';Fed=True')})]
        [string]
        $ClusterUrl,

        [Parameter(Mandatory)]
        [string]
        $DatabaseName
    )

    $Connection = @{
        ClusterUrl = $ClusterUrl
        DatabaseName = $DatabaseName
    }

    $PolicyParser = @(
        '| extend '
        '    parse_json(ChildEntities),'
        '    split(EntityName,@".")'
        '| extend '
        '    TargetDatabase = trim(@"[^\w]+",tostring(EntityName[0])),'
        '    TargetTable = trim(@"[^\w]+",tostring(EntityName[1]))'
        '| mv-expand parse_json(Policy)'
        '| extend '
        '    IsEnabled                    = tobool(Policy.IsEnabled),'
        '    Source                       = tostring(Policy.Source),'
        '    Query                        = tostring(Policy.Query),'
        '    IsTransactional              = tobool(Policy.IsTransactional),'
        '    PropagateIngestionProperties = tobool(Policy.PropagateIngestionProperties),'
        '    ManagedIdentity              = tostring(Policy.ManagedIdentity)'
        '| project-away Policy'
    ) 

    $UpdatePoliciesQuery = @(
        '.show table * policy update'
        $PolicyParser
    ) -join "`n"

    $RowLevelSecurityPoliciesQuery = @(
        '.show table * policy row_level_security'
        $PolicyParser
    ) -join "`n"

    $PartitioningPolicyQuery = @(
        '.show table * policy partitioning'
        '| extend EntityName = split(EntityName,@".")'
        '| extend'
        '    DatabaseName = trim(@"[^\w]+",tostring(EntityName[0])),'
        '    TableName = trim(@"[^\w]+",tostring(EntityName[1]))'
        '| project-away EntityName'
    ) -join "`n"

    $ContinuousExportQuery = @(
        '.show continuous-exports'
        '| extend CursorScopedTablesDynamic = parse_json(CursorScopedTables)'
        '| extend CursorScopedTables0 = tostring(CursorScopedTablesDynamic[0])'
        "| parse CursorScopedTables0 with * `"['`" Database0 `"'].['`" Table0 `"']`""
        '| project-away'
        '    CursorScopedTablesDynamic,'
        '    CursorScopedTables0'
        '| project-reorder *0'
    ) -join "`n"

    $ExternalTablesQuery = @(
        '.show external tables'
        '| extend'
        '    ConnectionStrings = dynamic_to_json(ConnectionStrings),'
        '    Partitions = dynamic_to_json(Partitions)'
    ) -join "`n"

    $RlsPolicies = Invoke-AdxCmd -Query $RowLevelSecurityPoliciesQuery @Connection
    $PartitionPolicies = Invoke-AdxCmd -Query $PartitioningPolicyQuery @Connection
    $UpdatePolicies = Invoke-AdxCmd -Query $UpdatePoliciesQuery @Connection
    $DatabasePolicy = Invoke-AdxCmd -Query '.show database policies' @Connection
    $TablesDetails = Invoke-AdxCmd -Query '.show tables details' @Connection
    $ContinuousExports = Invoke-AdxCmd -Query $ContinuousExportQuery @Connection
    $ExternalTables = Invoke-AdxCmd -Query $ExternalTablesQuery @Connection

    Invoke-AdxCmd -Query '.show database cslschema' @Connection | ForEach-Object {
        $Directory        = New-Item -ItemType Directory -Path "Tables/$($_.Folder)" -Force
        $TableName        = $_.TableName
        $TablePolicy      = $TablesDetails     | Where-Object TableName   -eq $TableName
        $UpdatePolicy     = $UpdatePolicies    | Where-Object TargetTable -eq $TableName
        $RlsPolicy        = $RlsPolicies       | Where-Object TargetTable -eq $TableName
        $PartitionPolicy  = $PartitionPolicies | Where-Object {
            $_.DatabaseName -eq $DatabaseName -and
            $_.TableName    -eq $TableName
        }
        $ContinuousExport = $ContinuousExports | Where-Object {
            $_.Database0 -eq $DatabaseName -and
            $_.Table0    -eq $TableName
        }
        $GetTableDdlSplat = @{
            CslSchemaDataRow = $_
            TablePolicy      = $TablePolicy
            DatabasePolicy   = $DatabasePolicy
            UpdatePolicy     = $UpdatePolicy
            RlsPolicy        = $RlsPolicy
            PartitionPolicy  = $PartitionPolicy
            ContinuousExport = $ContinuousExport
        }
        $CreateCmd = ConvertTo-AdxCreateTableCmd @GetTableDdlSplat
        $CreateCmd | Set-Content "${Directory}/${TableName}.kql"
    }

    foreach($ExternalTable in $ExternalTables){
        $TableName = $ExternalTable.TableName 
        $ExternalTableSchema = Invoke-AdxCmd -Query ".show external table ['$TableName'] cslschema" @Connection
        $Directory = New-Item -ItemType Directory -Path "ExternalTables/$($ExternalTable.Folder)" -Force
        ConvertTo-AdxCreateExternalTableCmd `
            -CslSchemaDataRow $ExternalTableSchema `
            -ExternalTableDataRow $ExternalTable `
        | Set-Content "$Directory/${TableName}.kql"
    }

    Invoke-AdxCmd -Query '.show functions' @Connection | ForEach-Object {
        $Directory = New-Item -ItemType Directory -Path "Functions/$($_.Folder)" -Force
        ConvertTo-AdxCreateFunctionCmd $_ | Set-Content "$Directory/$($_.Name).kql"
    }

    Invoke-AdxCmd -Query '.show materialized-views' @Connection | ForEach-Object {
        $Directory = New-Item -ItemType Directory -Path "MaterializedViews/$($_.Folder)" -Force
        ConvertTo-AdxCreateMaterializedViewCmd $_ | Set-Content "$Directory/$($_.Name).kql"
    }
}
