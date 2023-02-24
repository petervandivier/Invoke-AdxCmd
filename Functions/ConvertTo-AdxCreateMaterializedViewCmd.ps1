
function ConvertTo-AdxCreateMaterializedViewCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [AdxMaterializedViewCslSchemaDataRow]
        $CslSchemaDataRow
    )
    $createStub = ".create-or-alter materialized-view {WithClause} {Name} `n    on table {SourceTable} {`n{Query}`n}"

    $WithClause = New-KqlWithClause $CslSchemaDataRow.Folder $CslSchemaDataRow.DocString $CslSchemaDataRow.Lookback
    $createCmd = $createStub.Replace( 
        '{WithClause}', $WithClause
    ).Replace( 
        '{Name}', $CslSchemaDataRow.Name
    ).Replace(
        '{SourceTable}', $CslSchemaDataRow.SourceTable
    ).Replace(
        '{Query}', $CslSchemaDataRow.Query
    )

    return $createCmd
}
