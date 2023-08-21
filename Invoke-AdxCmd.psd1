@{
    RootModule = 'Invoke-AdxCmd.psm1'
    ModuleVersion = '0.1.0'
    Author = 'Peter Vandivier'
    FunctionsToExport = @(
        'Invoke-AdxCmd'
        # 
        'ConvertTo-AdxCreateFunctionCmd'
        'ConvertTo-AdxCreateMaterializedViewCmd'
        'ConvertTo-AdxCreateTableCmd'
        'Deploy-AdxObject'
        'Export-AdxDatabaseSchema'
        'Export-AdxTableData'
        'Format-KqlIdentifier'
        'Format-KqlParameters'
        'New-KqlWithClause'
        'Test-KqlKeyword'
    )
    VariablesToExport = @(
        'KqlReservedKeywords'
    )
    Guid = '688fd570-0253-491b-beff-385ecc05cef2'
}
