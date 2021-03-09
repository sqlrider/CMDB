

$instancesquery = "SELECT Hostname,InstanceName
                   FROM dbo.Instances"

$instances = Invoke-Sqlcmd -ServerInstance MyServer -Database 'TestDB' -Query $instancesquery


foreach ($instance in $instances)
{
    try
    {
        # SSAS
        $SSASinstances = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -EQ "SQL Server Analysis Services ($($instance.InstanceName))" | Where-Object -Property DisplayName -NotLike "*CEIP*" | Select-Object DisplayName, StartName, State, StartMode

        foreach($SSAS in $SSASinstances)
        {
            Write-Output $SSAS
        }
    }
    catch
    {
        "SSAS Error on $($instance.Hostname)\$($instance.InstanceName):" + $error[0]
    }

    try
    {
        # SSRS
        $SSRSinstances = Get-WmiObject Win32_Service -ComputerName $instance.Hostname | Where-Object -Property DisplayName -EQ "SQL Server Reporting Services ($($instance.InstanceName))" | Where-Object -Property DisplayName -NotLike "*CEIP*" | Select-Object DisplayName, StartName, State, StartMode

        foreach($SSRS in $SSRSinstances)
        {
            Write-Output $SSRS
        }
    }
        catch
    {
        Write-Output "SSRS Error on $($instance.Hostname)\$($instance.InstanceName):" + $error[0] 
    }


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
                Write-Output $SSIS 
            }
            elseif (($ConfigXML.DtsServiceConfiguration.TopLevelFolders.Folder.ServerName -EQ ".") -and ($instance.InstanceName -eq 'MSSQLSERVER'))
            {
                Write-Output $SSIS
            }
        }
    }
    catch
    {
        Write-Output "SSIS Error on $($instance.Hostname)\$($instance.InstanceName):" + $error[0]
    }
}