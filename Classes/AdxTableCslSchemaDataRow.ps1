
<#
.SYNOPSIS
    Output of `.show database cslschema` or `.show table <TableName> cslschema` command
.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/show-table-schema-command
.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/show-schema-database
#>
class AdxTableCslSchemaDataRow {
    [ValidateNotNullOrEmpty()][string]$TableName
    [ValidateNotNullOrEmpty()][string]$Schema
    [ValidateNotNullOrEmpty()][string]$DatabaseName
    [string]$Folder
    [string]$DocString
    AdxTableCslSchemaDataRow([System.Data.DataRowView]$DataRow){
        $this.TableName    = $DataRow.TableName
        $this.Schema       = $DataRow.Schema
        $this.DatabaseName = $DataRow.DatabaseName
        $this.Folder       = $DataRow.Folder
        $this.DocString    = $DataRow.DocString
    }
}
