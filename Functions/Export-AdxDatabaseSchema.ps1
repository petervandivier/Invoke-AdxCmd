
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

    $dbTables = Invoke-AdxCmd -Query '.show database cslschema'  -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName

    $dbTables | ForEach-Object {
        $createCmd = ConvertTo-AdxCreateTableCmd $_
        $_ | Add-Member -MemberType NoteProperty -Name CreateCmd -Value $createCmd
        $Directory = New-Item -ItemType Directory -Path "Tables/$($_.Folder)" -Force
        $createCmd | Set-Content "$Directory/$($_.TableName).kql"
    }

    $dbFunctions = Invoke-AdxCmd -Query '.show functions' -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName

    $dbFunctions | ForEach-Object {
        $createCmd = ConvertTo-AdxCreateFunctionCmd $_
        $_ | Add-Member -MemberType NoteProperty -Name CreateCmd -Value $createCmd
        $Directory = New-Item -ItemType Directory -Path "Functions/$($_.Folder)" -Force
        $createCmd | Set-Content "$Directory/$($_.Name).kql"
    }
}
