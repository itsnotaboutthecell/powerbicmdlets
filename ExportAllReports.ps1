Login-PowerBIServiceAccount

$pbiWorkspaces = Get-PowerBIWorkspace -Scope Organization
Write-Host "Total Number of Workspaces: $($pbiWorkspaces.Count)`n"

ForEach ($workspace in $pbiWorkspaces) {

    $pbiReports = Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id
    Write-Host "Current Workspace: $($workspace)"

    ForEach ($report in $pbiReports) {
        
        if (Test-Path "C:\temp\Power BI\$($report.Name).pbix" ) {
                Write-Host "File $($report.Name).pbix Already Exists in Current Directory"
        }
        else {
                Write-Host "Now Exporting Report: $($report.Name)"
                Export-PowerBIReport -WorkspaceId $workspace.Id -Id $report.Id -OutFile "C:\temp\Power BI\$($report.Name).pbix" 
        }
    }
}

Logout-PowerBIServiceAccount
