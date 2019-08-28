# Exports all Power BI reports within the current organization
# If you only want to export the reports you have access to change to -Scope Individual

Login-PowerBIServiceAccount

Get-PowerBIReport -Scope Individual | Export-Csv "C:\temp\Power BI\pbi_reports.csv" -NoTypeInformation

$pbiReports = Get-PowerBIReport -Scope Organization

ForEach ($Result in $pbiReports) {

    Write-Host "Report Id: $($Result.Id) - Report Name: $($Result.Name)"
    Export-PowerBIReport -Id $($Result.Id) -OutFile "C:\temp\Power BI\$($Result.Name).pbix"

}

Logout-PowerBIServiceAccount
