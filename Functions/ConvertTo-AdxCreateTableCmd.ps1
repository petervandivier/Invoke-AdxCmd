
function ConvertTo-AdxCreateTableCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [AdxTableCslSchemaDatarow]
        $TableCslSchemaDataRow
    )
    $createTblStub = ".create-merge table {TableName} (`n{ColumnList}`n) {WithClause}"

    $WithClause = New-KqlWithClause $TableCslSchemaDataRow.Folder $TableCslSchemaDataRow.DocString
    $ColumnList = ($TableCslSchemaDataRow.Schema.Split(',') | ForEach-Object {
        "    $($_.Replace(':', ': '))"
    }) -join ",$([Environment]::NewLine)"
    $createCmd = $createTblStub.Replace(
        '{TableName}', $TableCslSchemaDataRow.TableName
    ).Replace(
        '{ColumnList}', $ColumnList
    ).Replace(
        '{WithClause}', $WithClause
    )
    return $createCmd
}
