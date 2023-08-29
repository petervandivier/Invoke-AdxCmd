# Change Log

## 0.1.1

Tuesday, 29th August, 2023

- Adds support for [row-level-security](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/management/rowlevelsecuritypolicy) to `.create table` outputs
- Bugfix: Update Policy syntax was previously outputting integers instead of booleans and was missing the `IsEnabled` property entirely. Update Policy JSON must be an array.
- Adds Change Log 🙂
