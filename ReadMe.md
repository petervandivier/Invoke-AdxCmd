# Invoke-AdxCmd

Once upon a time, I asked StackOverflow ["How to query ADX from PowerShell?"](https://stackoverflow.com/q/75315624/4709762). To support that use case, I created this module.

Started as a lightweight PowerShell wrapper to connect to Azure Data Explorer and execute arbitrary KQL. Grown to include utility functions for interacting with an ADX cluster.

# Arcana

If you're on this page, you probably already know what KQL & ADX are, but so we're all on the same page as to the module author's understanding...

## ADX

[Azure Data Explorer](https://learn.microsoft.com/en-us/azure/data-explorer/) is a SAAS timeseries database with some relational DBMS flair added. It is distinct from [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview) although they are both informally called "Kusto" since KQL is used to interact with both. Note Log Analytics has native PowerShell→KQL support in `Invoke-AzOperationalInsightsQuery` <sub>([docs](https://learn.microsoft.com/en-us/powershell/module/az.operationalinsights/invoke-azoperationalinsightsquery), [source](https://learn.microsoft.com/en-us/powershell/module/az.operationalinsights/invoke-azoperationalinsightsquery), [blog](https://learningbydoing.cloud/blog/query-log-analytics-with-kql-from-powershell/))</sub>. This module is only for use with ADX (although some of the utility functions (prefixed KQL instead of ADX) may be portable). 

## KQL

[Kusto Query Language](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/) is the syntax you use for interacting with ADX, [Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview), and [Azure Resource Graph](https://learn.microsoft.com/en-us/azure/governance/resource-graph/overview) Explorer <sub>[`Search-AzGraph`](https://learn.microsoft.com/en-us/powershell/module/az.resourcegraph/search-azgraph)</sub>. 

Also sometimes abbreviated as CSL. This stands for "Costeau Semantic Language" and was the internal project name at Microsoft before general availability (sadly I have only [informal citations for this](https://twitter.com/TechTrainerTim/status/1534521353503637504)). 
