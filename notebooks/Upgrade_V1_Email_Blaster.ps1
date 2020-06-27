# Declare Variables
$outPath = "C:\Power BI\Activity Logs\"
$senderAddress = 'email@domain.com'
 
# Gets Previous X Days Events – Max Value 89
$offsetDays = 7
 
$pbiEvents = # Create
                'CreateReport', 'CreateDataset', 'CreateDashboard',
             # Read
                'ShareDashboard','ShareReport',
             # Update
                 'EditReport', 'EditDataset', 'EditDashboard', 'RefreshDataset', 'SetScheduledRefresh',
             # Delete
                 'DeleteReport', 'DeleteDataset', 'DeleteDashboard'
 
############### SCRIPT BEGINS ###############
Connect-PowerBIServiceAccount # -ServicePrincipal -Credential (Get-Credential)
 
# Erorr Handling: outPath - Final character is forward slash and folder exists
if ($outPath.Substring($outPath.Length - 1, 1) -cne "\") { $outPath = $outPath + "\" } 
if (!(Test-Path $outPath)) { New-Item -ItemType Directory -Force -Path $outPath }
 
# Get Active Power BI v1 Workspaces
$pbiWorkspaces = Get-PowerBIWorkspace -Scope Organization -Filter "type eq 'Group'" | Where-Object {$_.State -eq "Active"} | select-object -property @{N='WorkspaceId';E={$_.Id}}, Name, isReadOnly, isOnDedicatedCapacity, CapacityId, Description, Type, State, IsOrphaned
$pbiWorkspaces | Export-Csv -Path "$($outpath)v1_Workspaces.csv" -NoTypeInformation
Write-Host "Total Number of Workspaces Being Evaluated: $($pbiWorkspaces.Count)`n"
 
# Iterates Offset Date Range
For ($i = 1; $i -le $offsetDays; $i+=1) { 
    $startEvent = ((Get-Date).AddDays(-$i).ToString("yyyy-MM-ddT00:00:00"))
    $endEvent = ((Get-Date).AddDays(-$i).ToString("yyyy-MM-ddT23:59:59"))
 
ForEach ( $activity in $pbiEvents ) {
 
    $pbiActivities = Get-PowerBIActivityEvent -StartDateTime $startEvent -EndDateTime $endEvent -ActivityType $activity | ConvertFrom-Json
    Write-Host "Evaluating $($startEvent.Substring(0,10)): $($activity) - $($pbiActivities.Count) Total Activities"
 
        if ($pbiActivities.Count -ne 0) {
            Compare-Object $pbiActivities -DifferenceObject $pbiWorkspaces -Property 'WorkspaceId' -IncludeEqual -ExcludeDifferent -PassThru |
            ForEach ` { 
                $_ | Select * -ExcludeProperty SideIndicator
            } | Where-Object {$_.RecordType -ne $null} | Export-Csv -Path "$($outpath)Power_BI_V1_Activity_Logs.csv" -NoTypeInformation -Force -Append
    }}}
 
Disconnect-PowerBIServiceAccount
 
############### E-MAIL BLASTER BEGINS ###############
 
if ($outPath.Substring($outPath.Length - 1, 1) -cne "\") { $outPath = $outPath + "\" } 
 
$existingWorkspaces = Import-CSV -Path "$($outPath)v1_Workspaces.csv"
$v1Activities = Import-Csv -Path "$($outPath)\Power_BI_V1_Activity_Logs.csv"
$V1Users = $v1Activities | Select UserId -Unique
 
#Get an Outlook application object
$o = New-Object -com Outlook.Application
 
ForEach ($v1User in $V1Users) {
 
    $V1Workspaces = $v1Activities | Select UserId, WorkSpaceName, WorkspaceId -Unique | Where-Object {$_.UserId -eq $v1User.UserId}
 
    if ($V1Workspaces.Count -ne 0) {
 
        $mail = $o.CreateItem(0)
 
        $mail.Sender= $senderAddress
        $mail.To = $v1User.UserId
        $mail.Subject = 'Action Required: Upgrade Power BI Workspace(s)'
        $mail.HtmlBody = (Compare-Object -ReferenceObject $existingWorkspaces -DifferenceObject $V1Workspaces -Property 'WorkspaceId' -IncludeEqual -ExcludeDifferent -PassThru |
                ForEach ` { $_ | Select Name, WorkspaceId, @{l="URL";e={"https://app.powerbi.com/groups/$($_.WorkspaceId)"}}} | 
                ConvertTo-HTML -Title 'Power BI Workspace Upgrade' -Body 'The following Power BI workspace(s) are currently out of compliance. Please visit the URL(s) below to upgrade now.<br><br>For instructions on how to upgrade classic workspaces to the new workspace experience, <a href="https://docs.microsoft.com/en-us/power-bi/designer/service-upgrade-workspaces">click here</a> to learn more.<br><br>' -PostContent "<br>Thank you in advance for your time and assistance." | Out-String )
        $mail.Importance = 2
 
        $mail.Send()
 
        # give time to send the email
        Start-Sleep 10
 
    }
}
# quit Outlook and exit script
$o.Quit()
exit
