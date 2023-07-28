function Test-KqlKeyword {
<#
.Synopsis
    Tests whether the input is a known KQL reserved keyword.

.Description
    TODO: make this list more exhaustive. See StackOverflow post linked below.

.Link
    https://stackoverflow.com/questions/76783075/what-are-the-kql-reserved-keywords

.Outputs
    [bool]
#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]
        $Word
    )

    $IsReservedKeyword = $Word -in $KqlReservedKeywords

    return $IsReservedKeyword
}
