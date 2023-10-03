
<#
.SYNOPSIS
    Output of `.show external tables` command. Does not contain CslSchema
.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/show-external-tables
#>
class AdxExternalTableDataRow {
    [ValidateNotNullOrEmpty()][string]$TableName
    [ValidateNotNullOrEmpty()][string]$TableType
    [string]$Folder
    [string]$DocString
    [ValidateNotNullOrEmpty()][string]$Properties
    [ValidateNotNullOrEmpty()][string[]]$ConnectionStrings
    [ValidateNotNullOrEmpty()][string[]]$Partitions
    [ValidateNotNullOrEmpty()][string]$PathFormat
    [string]$Catalog
    AdxTableCslTableTypeDataRow([System.Data.DataRowView]$DataRow){
        $this.TableName         = $DataRow.TableName
        $this.Schema            = $DataRow.Schema
        $this.Folder            = $DataRow.Folder
        $this.DocString         = $DataRow.DocString
        $this.Properties        = $DataRow.Properties
        $this.ConnectionStrings = $DataRow.ConnectionStrings
        $this.Partitions        = $DataRow.Partitions
        $this.PathFormat        = $DataRow.PathFormat
        $this.Catalog           = $DataRow.Catalog
    }
}
