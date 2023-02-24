
function ConvertTo-AdxCreateMaterializedViewCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [AdxMaterializedViewCslSchemaDataRow]
        $CslSchemaDataRow
    )
    $createStub = ".create-or-alter materialized-view {Name} `n    on table {SourceTable} {`n{Query}`n}"

    $createCmd = $createStub.Replace( 
        '{Name}', $CslSchemaDataRow.Name
    ).Replace(
        '{SourceTable}', $CslSchemaDataRow.SourceTable
    ).Replace(
        '{Query}', $CslSchemaDataRow.Query
    )

    return $createCmd
}
