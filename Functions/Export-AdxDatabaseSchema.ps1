
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
    $createTblStub = @"
.create-merge table {TableName} (
{ColumnList}
) {WithClause}
"@

    $dbTables | ForEach-Object {
        $WithClause = New-KqlWithClause $_.Folder $_.DocString
        $ColumnList = ($_.Schema.Split(',') | ForEach-Object {
            "    $($_.Replace(':', ': '))"
        }) -join ",$([Environment]::NewLine)"
        $createCmd = $createTblStub.Replace(
            '{TableName}', $_.TableName
        ).Replace(
            '{ColumnList}', $ColumnList
        ).Replace(
            '{WithClause}', $WithClause
        )
        $_ | Add-Member -MemberType NoteProperty -Name CreateCmd -Value $createCmd
        $Directory = New-Item -ItemType Directory -Path "Tables/$($_.Folder)" -Force
        $createCmd | Set-Content "$Directory/$($_.TableName).kql"
    }

    $dbFunctions = Invoke-AdxCmd -Query '.show functions' -ClusterUrl $ClusterUrl -DatabaseName $DatabaseName
    $createFuncStub = @"
.create-or-alter function {WithClause} {Name} {Parameters} {Body}
"@

    $dbFunctions | ForEach-Object {
        $WithClause = New-KqlWithClause $_.Folder $_.DocString
        $Parameters = Format-KqlParameters $_.Parameters
        $createCmd = $createFuncStub.Replace( 
            '{WithClause}', $WithClause
        ).Replace( 
            '{Name}', $_.Name
        ).Replace(
            '{Parameters}', $Parameters
        ).Replace(
            '{Body}', $_.Body
        )
        $_ | Add-Member -MemberType NoteProperty -Name CreateCmd -Value $createCmd
        $Directory = New-Item -ItemType Directory -Path "Functions/$($_.Folder)" -Force
        $createCmd | Set-Content "$Directory/$($_.Name).kql"
    }
}
