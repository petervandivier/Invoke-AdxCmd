
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

    Invoke-AdxCmd -Query '.show database cslschema' @Connection | ForEach-Object {
        $Directory = New-Item -ItemType Directory -Path "Tables/$($_.Folder)" -Force
        ConvertTo-AdxCreateTableCmd $_ | Set-Content "$Directory/$($_.TableName).kql"
    }

    Invoke-AdxCmd -Query '.show functions' @Connection| ForEach-Object {
        $Directory = New-Item -ItemType Directory -Path "Functions/$($_.Folder)" -Force
        ConvertTo-AdxCreateFunctionCmd $_ | Set-Content "$Directory/$($_.Name).kql"
    }

    Invoke-AdxCmd -Query '.show materialized-views' @Connection | ForEach-Object {
        $Directory = New-Item -ItemType Directory -Path "MaterializedViews/$($_.Folder)" -Force
        ConvertTo-AdxCreateFunctionCmd $_ | Set-Content "$Directory/$($_.Name).kql"
    }
}
