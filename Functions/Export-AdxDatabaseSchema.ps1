
function Export-AdxDatabaseSchema {
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

    $UpdatePoliciesQuery = @(
        '.show table * policy update'
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
    ) -join "`n"

    $UpdatePolicies = Invoke-AdxCmd -Query $UpdatePoliciesQuery @Connection
    $DatabasePolicy = Invoke-AdxCmd -Query '.show database policies' @Connection
    $TablesDetails = Invoke-AdxCmd -Query '.show tables details' @Connection

    Invoke-AdxCmd -Query '.show database cslschema' @Connection | ForEach-Object {
        $Directory = New-Item -ItemType Directory -Path "Tables/$($_.Folder)" -Force
        $TableName = $_.TableName
        $TablePolicy = $TablesDetails | Where-Object TableName -eq $TableName
        $UpdatePolicy = $UpdatePolicies | Where-Object TargetTable -eq $TableName
        $CreateCmd = ConvertTo-AdxCreateTableCmd `
            -CslSchemaDataRow $_ `
            -TablePolicy $TablePolicy `
            -DatabasePolicy $DatabasePolicy `
            -UpdatePolicy $UpdatePolicy
        $CreateCmd | Set-Content "${Directory}/${TableName}.kql"
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
