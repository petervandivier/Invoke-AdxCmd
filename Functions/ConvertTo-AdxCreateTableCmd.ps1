
function ConvertTo-AdxCreateTableCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [AdxTableCslSchemaDatarow]
        $CslSchemaDataRow
    )
    $createStub = ".create-merge table {TableName} (`n{ColumnList}`n) {WithClause}"

    $WithClause = New-KqlWithClause $CslSchemaDataRow.Folder $CslSchemaDataRow.DocString
    $ColumnList = ($CslSchemaDataRow.Schema.Split(',') | ForEach-Object {
        "    $($_.Replace(':', ': '))"
    }) -join ",$([Environment]::NewLine)"
    $createCmd = $createStub.Replace(
        '{TableName}', $CslSchemaDataRow.TableName
    ).Replace(
        '{ColumnList}', $ColumnList
    ).Replace(
        '{WithClause}', $WithClause
    )
    return $createCmd
}
