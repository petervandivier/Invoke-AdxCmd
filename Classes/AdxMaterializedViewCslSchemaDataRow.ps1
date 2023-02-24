
<#
.SYNOPSIS
    Output of `.show materialized-views` command
.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/materialized-views/materialized-view-show-commands
.PARAMETER Lookback
    Lookback type cannot be declared since ADX allows for nullable [timespan] while PowerShell does not
.LINK
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/scalar-data-types/timespan
.LINK
    https://www.softwarepronto.com/2021/07/powershell-nullable-types.html
#>
class AdxMaterializedViewCslSchemaDataRow {
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNullOrEmpty()][string]$SourceTable
    [ValidateNotNullOrEmpty()][string]$Query
    [datetime]$MaterializedTo
    [datetime]$LastRun
    [string]$LastRunResult
    [bool]$IsHealthy
    [bool]$IsEnabled
    [string]$Folder
    [string]$DocString
    [bool]$AutoUpdateSchema
    [datetime]$EffectiveDateTime
    $Lookback
    AdxMaterializedViewCslSchemaDataRow([System.Data.DataRowView]$DataRow){
        $this.Name              = $DataRow.Name
        $this.SourceTable       = $DataRow.SourceTable
        $this.Query             = $DataRow.Query
        $this.MaterializedTo    = $DataRow.MaterializedTo
        $this.LastRun           = $DataRow.LastRun
        $this.LastRunResult     = $DataRow.LastRunResult
        $this.IsHealthy         = $DataRow.IsHealthy
        $this.IsEnabled         = $DataRow.IsEnabled
        $this.Folder            = $DataRow.Folder
        $this.DocString         = $DataRow.DocString
        $this.AutoUpdateSchema  = $DataRow.AutoUpdateSchema
        $this.EffectiveDateTime = $DataRow.EffectiveDateTime
        $this.Lookback          = if($DataRow.Lookback -is [System.DBNull]){$null}else{[timespan]($DataRow.Lookback)}
    }
}
