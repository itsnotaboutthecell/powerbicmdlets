$pbiModules = @("MicrosoftPowerBIMGMT", "DataGateway")

foreach ( $m in $pbiModules ) 
{
    if (Get-Module -ListAvailable -Name $m) {
        write-host "Module $m is already imported."
    } 
    else {
        Install-Module -Name $m -Force -Verbose -Scope CurrentUser
        Import-Module $m -Verbose
    }
}
