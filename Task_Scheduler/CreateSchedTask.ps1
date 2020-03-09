function CreateSchedTask(){
	$start1 = $($(Get-Date).Hour).ToString() + ":" + $($(Get-Date).Minute+1).ToString() + ":00"
	$start2 = $($(Get-Date).Hour).ToString() + ":" + $($(Get-Date).Minute+1).ToString() + ":10"
	$start3 = $($(Get-Date).Hour).ToString() + ":" + $($(Get-Date).Minute+1).ToString() + ":20"
	$start4 = $($(Get-Date).Hour).ToString() + ":" + $($(Get-Date).Minute+1).ToString() + ":30"
	$start5 = $($(Get-Date).Hour).ToString() + ":" + $($(Get-Date).Minute+1).ToString() + ":40"
	$start6 = $($(Get-Date).Hour).ToString() + ":" + $($(Get-Date).Minute+1).ToString() + ":50"

	$Trigger= @(
		$(New-ScheduledTaskTrigger -Once -At $start1 -RepetitionInterval (New-TimeSpan -Minutes 1))
		$(New-ScheduledTaskTrigger -Once -At $start2 -RepetitionInterval (New-TimeSpan -Minutes 1))
		$(New-ScheduledTaskTrigger -Once -At $start3 -RepetitionInterval (New-TimeSpan -Minutes 1))
		$(New-ScheduledTaskTrigger -Once -At $start4 -RepetitionInterval (New-TimeSpan -Minutes 1))
		$(New-ScheduledTaskTrigger -Once -At $start5 -RepetitionInterval (New-TimeSpan -Minutes 1))
		$(New-ScheduledTaskTrigger -Once -At $start6 -RepetitionInterval (New-TimeSpan -Minutes 1))
	)

	$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest

	$setting = New-ScheduledTaskSettingsSet -WakeToRun -ExecutionTimeLimit 30 -RestartInterval $(New-TimeSpan -Minutes 1) -RestartCount 3  -MultipleInstances Queue -Priority 0 -StartWhenAvailable

	$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-file $ScriptDir\FailoverCluster_Monitor_Bot.ps1" # Specify what program to run and with its parameters
	$desc = "This task runs every 1 minute to do health check of the SMS Gateway Application`nThis task is responsible to maintain High Availability of MariaDB.`n Please update the configuration details in the config file 'C:\Failover_cluster_Monitoring_Bot\FailoverCluster_Monitor_Bot.ini'" 

	try{
		Register-ScheduledTask -TaskName "Monitor_Failover_Cluster" -Description $desc -Trigger $Trigger -Action $Action -Principal $principal -settings $setting -Force # Specify the name of the task
		$created = $True
	}
	catch{
		write-host "Unable to create schedule Task, Please create it manually!!"
		$created = $False
	}
	if ($created){
		Write-Host "Scheduled Task Created Successfully"
		Start-ScheduledTask -TaskName "Monitor_Failover_Cluster"
	}

}
