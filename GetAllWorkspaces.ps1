Connect-PowerBIServiceAccount

# Exports Power BI Workspace Information
Set-Variable -Name OutPath -Value C:\Temp\
$workspaces = Get-PowerBIWorkspace -All

Export-Csv -InputObject $workspaces -NoTypeInformation -Path "$($OutPath)workspaces.csv"

Write-Host "Total Number of Workspaces: $($workspaces.Count)`n"
Disconnect-PowerBIServiceAccount

Read-Host "Press any key when complete."
