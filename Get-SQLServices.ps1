

<#
$instancesquery = "SELECT Hostname, InstanceName
                   FROM dbo.Instances"

$instances = Invoke-Sqlcmd -ServerInstance SQL2017A -Database 'TestDB' -Query $instancesquery
#>

$instances = Import-Csv -Path "C:\temp\servers.txt"


foreach ($instance in $instances)
{
    Write-Output "Connecting to $($instance.Hostname)\$($instance.InstanceName).."

    try
    {
        $test = Get-WmiObject Win32_Service -ComputerName $instance.Hostname -ErrorAction Stop
    }
    catch
    {
        Write-Output "Error connecting remotely to WMI"

        continue
    }

    # Database Engine
    $DatabaseEngine = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -EQ "SQL Server ($($instance.InstanceName))" | Select-Object DisplayName, StartName, State, Startmode

    Write-Output $DatabaseEngine


    # Database Engine
    $SQLAgent = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -EQ "SQL Server Agent ($($instance.InstanceName))" | Select-Object DisplayName, StartName, State, Startmode

    Write-Output $SQLAgent


    # SSAS
    $SSAS = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -EQ "SQL Server Analysis Services ($($instance.InstanceName))" | Where-Object -Property DisplayName -NotLike "*CEIP*" | Select-Object DisplayName, StartName, State, StartMode

    Write-Output $SSAS


    # SSRS
    $SSRS = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -EQ "SQL Server Reporting Services ($($instance.InstanceName))" | Where-Object -Property DisplayName -NotLike "*CEIP*" | Select-Object DisplayName, StartName, State, StartMode

    Write-Output $SSRS


    #SSIS
    $SSISinstances = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -Like "SQL Server Integration Services*" | Where-Object -Property DisplayName -NotLike "*CEIP*" | Select-Object DisplayName, PathName, StartName, State, StartMode

    try
    {
        foreach($SSIS in $SSISinstances)
        {   
            $ConfigXMLPath = ($SSIS.PathName.Substring(0,$SSIS.PathName.IndexOf('MsDtsSrvr.exe')) + 'MsDtsSrvr.ini.xml') -replace '"', ''

            $ConfigXMLPath = "\\$($instance.Hostname)\" + $SSIS.PathName.Substring(1,1) + '$\' + $ConfigXMLPath.Substring(3)

            [xml]$ConfigXML = Get-Content -Path $ConfigXMLPath       
        
            if ($ConfigXML.DtsServiceConfiguration.TopLevelFolders.Folder.ServerName -like "*$($instance.InstanceName)*")
            {
                Write-Output ($SSIS | Select-Object DisplayName, StartName, State, StartMode)
            }
            elseif (($ConfigXML.DtsServiceConfiguration.TopLevelFolders.Folder.ServerName -EQ ".") -and ($instance.InstanceName -eq 'MSSQLSERVER'))
            {
                Write-Output ($SSIS | Select-Object DisplayName, StartName, State, StartMode)
            }
        }
    }
    catch
    {
        Write-Output "SSIS Error: " + $error[0]
    }
}