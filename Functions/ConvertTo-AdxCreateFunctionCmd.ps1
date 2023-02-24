
function ConvertTo-AdxCreateFunctionCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [AdxFunctionCslSchemaDataRow]
        $CslSchemaDataRow
    )
    $createStub = ".create-or-alter function {WithClause} {Name} {Parameters} {Body}"

    $WithClause = New-KqlWithClause $CslSchemaDataRow.Folder $CslSchemaDataRow.DocString
    $Parameters = Format-KqlParameters $CslSchemaDataRow.Parameters
    $createCmd = $createStub.Replace( 
        '{WithClause}', $WithClause
    ).Replace( 
        '{Name}', $CslSchemaDataRow.Name
    ).Replace(
        '{Parameters}', $Parameters
    ).Replace(
        '{Body}', $CslSchemaDataRow.Body
    )

    return $createCmd
}
