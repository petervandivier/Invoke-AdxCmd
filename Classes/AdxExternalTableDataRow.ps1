
<#
.Synopsis
    Output of `.show external tables` command. Does not contain CslSchema

.Description
    Unfortunately there appears to be a bug for the `dynamic` data type handler
    as of this writing. 

    > Error: Unable to cast object of type 'Newtonsoft.Json.Linq.JValue' to type 'System.String'.

    For this reason we will manually cast the following incoming `dynamic` properties to text
    upstream of class assignment for now.
        - ConnectionStrings
        - Partitions

.Link
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/show-external-tables
#>
class AdxExternalTableDataRow {
    [ValidateNotNullOrEmpty()][string]$TableName
    [ValidateNotNullOrEmpty()][string]$TableType
    [string]$Folder
    [string]$DocString
    [ValidateNotNullOrEmpty()]$Properties
    [ValidateNotNullOrEmpty()][string[]]$ConnectionStrings
    $Partitions
    [string]$PathFormat
    [string]$Catalog
    AdxExternalTableDataRow([System.Data.DataRowView]$DataRow){
        $this.TableName         = $DataRow.TableName
        $this.TableType         = $DataRow.TableType
        $this.Folder            = $DataRow.Folder
        $this.DocString         = $DataRow.DocString
        $this.Properties        = $DataRow.Properties | ConvertFrom-Json
        $this.ConnectionStrings = [string[]]($DataRow.ConnectionStrings | ConvertFrom-Json)
        $this.Partitions        = [string[]]($DataRow.Partitions | ConvertFrom-Json)
        $this.PathFormat        = $DataRow.PathFormat
        $this.Catalog           = $DataRow.Catalog
    }
}
