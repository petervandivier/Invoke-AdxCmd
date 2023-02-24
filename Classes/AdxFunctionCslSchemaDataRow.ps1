
<#
.SYNOPSIS
    Output of `.show functions` command
.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/show-function
#>
class AdxFunctionCslSchemaDataRow {
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNullOrEmpty()][string]$Parameters
    [ValidateNotNullOrEmpty()][string]$Body
    [string]$Folder
    [string]$DocString
    AdxFunctionCslSchemaDataRow([System.Data.DataRowView]$DataRow){
        $this.Name       = $DataRow.Name
        $this.Parameters = $DataRow.Parameters
        $this.Body       = $DataRow.Body
        $this.Folder     = $DataRow.Folder
        $this.DocString  = $DataRow.DocString
    }
}
