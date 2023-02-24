@{
    RootModule = 'Invoke-AdxCmd.psm1'
    ModuleVersion = '0.0.7'
    Author = 'Peter Vandivier'
    FunctionsToExport = @(
        'Invoke-AdxCmd'
        # 
        'ConvertTo-AdxCreateFunctionCmd'
        'ConvertTo-AdxCreateTableCmd'
        'Deploy-AdxObject'
        'Export-AdxDatabaseSchema'
        'Export-AdxTableData'
        'Format-KqlParameters'
        'New-KqlWithClause'
    )
    Guid = '688fd570-0253-491b-beff-385ecc05cef2'
}
