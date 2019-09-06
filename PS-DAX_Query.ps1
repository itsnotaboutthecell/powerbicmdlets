#input the DAX query here that should run against the endpoint
$DAXQuery = "EVALUATE Customers"

    #database and server details
    $DatabaseName = "1cb589b5-14a8-42e3-a731-9b73444cb569"
    $ServerAddress = "localhost:60215"

    #output location
    $outputFolder = "C:\temp\Power BI\"
    $OutputName = "Customers_Output"

    #compile the final output filepath including the filename
    $outFile = "$OutputFolder\$OutputName.csv"

    #install and load adomdnet if needed
    function InstallAndLoadAdomdNet {
        "Installing ADOMD.NET"
        $null = Register-PackageSource -Name nuget.org -Location http://www.nuget.org/api/v2 -Force -Trusted -ProviderName NuGet;
        $install = Install-Package Microsoft.AnalysisServices.AdomdClient.retail.amd64 -ProviderName NuGet -Force;
        $dllPath = $install.Payload.Directories[0].Location + "\" + $install.Payload.Directories[0].Name + "\lib\net45\Microsoft.AnalysisServices.AdomdClient.dll";
        $bytes = [System.IO.File]::ReadAllBytes($dllPath)
        return [System.Reflection.Assembly]::Load($bytes)
    }
    if ($assembly -eq $null)
    {
        $assembly = InstallAndLoadAdomdNet;
    }
    
    #create the Analysis Services connection object
    $conn = New-Object -TypeName Microsoft.AnalysisServices.AdomdClient.AdomdConnection;
    $conn.ConnectionString = "Provider=MSOLAP;Initial Catalog=$DatabaseName;Data Source=$ServerAddress;MDX Compatibility=1;Safety Options=2;MDX Missing Member Mode=Error;Update Isolation Level=2"
    $conn.Open();

    #create the AS command
    $cmd = New-Object -TypeName Microsoft.AnalysisServices.AdomdClient.AdomdCommand;
    $cmd.Connection = $conn;
    $cmd.CommandTimeout = 600;
    $cmd.CommandText = $DAXQuery

    #fill a dataset object with the result of the cmd
    $da = new-Object Microsoft.AnalysisServices.AdomdClient.AdomdDataAdapter($cmd)
    $ds = new-Object System.Data.DataSet
    $rowCount = $da.Fill($ds)
    
    #close your connection
    $conn.Close();
    $conn = $null;

    #export the result set as a csv
    return @($ds.Tables[0]) | Export-Csv -Path $outFile -NoTypeInformation
