function Format-KqlIdentifier {
<#
.Synopsis
    Takes a string and `quotename`s it IF NEEDED to be a valid KQL identifier

.Link
    https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/schema-entities/entity-names

.Outputs
    [string]
#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [ValidateLength(1,1024)]
        [string]
        $Identifier
    )

    if(Test-KqlKeyword $Identifier){
        return "['$Identifier']"
    }

    if($Identifier -match '[^a-zA-Z0-9_]'){
        return "['$Identifier']"
    }

    if($Identifier.StartsWith('__')){
        # n.b. docs indicate `.EndsWith('__')` as an invalid format, but testing belies this
        throw "The Kusto Query Language reserves all identifiers that start with a sequence of two underscore characters (__); users can't define such names for their own use."
    }

    return $Identifier
}
