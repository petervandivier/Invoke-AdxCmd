
function ConvertTo-AdxCreateFunctionCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [AdxFunctionCslSchemaDataRow]
        $TableCslSchemaDataRow
    )
    $createFuncStub = ".create-or-alter function {WithClause} {Name} {Parameters} {Body}"

    $WithClause = New-KqlWithClause $TableCslSchemaDataRow.Folder $TableCslSchemaDataRow.DocString
    $Parameters = Format-KqlParameters $TableCslSchemaDataRow.Parameters
    $createCmd = $createFuncStub.Replace( 
        '{WithClause}', $WithClause
    ).Replace( 
        '{Name}', $TableCslSchemaDataRow.Name
    ).Replace(
        '{Parameters}', $Parameters
    ).Replace(
        '{Body}', $TableCslSchemaDataRow.Body
    )

    return $createCmd
}
