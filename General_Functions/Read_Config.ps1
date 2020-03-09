if(test-path -Path $configFile) 
{
    Get-Content $ConfigFile | foreach-object -begin {$config=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True) -and ($k[0].StartsWith("#") -ne $True)) { $config.Add($k[0], $k[1]) } } 

    $configContent = $config.getenumerator()  | Sort-Object  'Name' | Select-Object 'Name','Value'    
    $Error.Clear()

    #region Initiating Variables
    $GLOBAL:output = $config.output_path
    $GLOBAL:SrvName = $config.app_srv_name
    $GLOBAL:appUrl = $config.app_url
	$Global:SendEmailReport=$config.SendEmailReport
    $GLOBAL:SmtpServer=$config.SMTP_Mail_Server
    $GLOBAL:EmailFrom=$config.From_Address
    $GLOBAL:EmailTo=$config.To_Address
	$GLOBAL:Log_duration=[int]$config.Log_duration
	$GLOBAL:port=$config.port
	$GLOBAL:failover_delay=[int]$config.failover_delay
	
	$GLOBAL:passpath="$Global:ScriptPath\password.txt"	
	if ($GLOBAL:output -eq '' ){
        $GLOBAL:output = "$Global:ScriptPath\Output"
    }
}else{
    Write-log  "Configuration file $configFile hasn't found, Please place the file and re-run..."
    Exit(0)
}
