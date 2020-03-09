<#
.SYNOPSIS
    Create_Clsuter_Task.ps1

.DESCRIPTION
  Creates Failover Cluster if Clsuter parameters are provided else creates Scheduled task alone.

.PARAMETER <Parameter_Name>
  ClusterName - Provide Cluster Name in this Field
  Nodes - Provide all the nodes hostname or the IP address to add in the clusters in  comma separated values
  VirtualIP - provide Virtual ipaddress for the cluster

.INPUTS
  ClusterName - Provide Cluster Name in this Field
  Nodes - Provide all the nodes hostname or the IP address to add in the clusters in  comma separated values
  VirtualIP - provide Virtual ipaddress for the cluster
  
.OUTPUTS
  No Outputs

.NOTES
  Script:         Cluster and Scheduled task creation script
  Author:         Hariharan MS | hariharan.srinivasan@atmecs.com 
  Requirements:   Powershell v4.0, Windows Server 2008, Windows Server 2008 R2 or later.
  Creation Date:  06/08/19
  Modified Date:  06/08/19


.History:
        Version Date            Author                Description        
        1.0     06/08/19        Hariharan MS         Created Functions to create cluster and Scheduled task.
.EXAMPLE
.\Create_Clsuter_Task.ps1 -ClusterName "ClusterName" -Nodes "srv1,srv2,srv3" -VirtualIP "xx.xx.xx.xx"
Above command is to Create Cluster and Scheduled Task
.EXAMPLE	
.\Create_Clsuter_Task.ps1
Above command is to Create Scheduled Task only
#>


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False)]
    [string]$ClusterName,
	[Parameter(Mandatory=$False)]
    [string]$VirtualIP,
	[Parameter(Mandatory=$False)]
    [string]$Nodes,
	[Parameter(Mandatory=$True)]
    [String]$CreateTask
)

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


function install_cluster_feature(){
	try{
		Install-WindowsFeature -Name "Failover-Clustering" -IncludeAllSubFeature -includemanagementtools
		$status = "pass"
		write-host "failover Cluster feature installed successfully"
	}
	catch{
		write-host "Unable to install Failover clustering Feature."
		$status = "fail"
	}

	return $status
}



function Create_Cluster($ClusterName,$nodes,$VirtualIP){
	if ($nodes -match ","){
		$arrNodes = $Nodes.split(",")
	}else{
		$arrNodes = $Nodes
	}
	try{

		import-module failoverclusters
		New-Cluster -Name $ClusterName -Node $arrNodes -StaticAddress $VirtualIP
	}
	catch{
		write-error "$error[0]"
		Write-Host "Unable to create Cluster, Please create it manually!!"
	}
}

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path 


if ($ClusterName -eq $null -or $ClusterName -eq "" ){

	Write-Host "Skipping Cluster Creation"

}else{
	Write-Host "Installing failover Cluster feature"
	$status = install_cluster_feature

	if ($status -eq "pass"){

		Write-Host "Creating Cluster - $ClusterName"
		Create_Cluster $ClusterName $nodes $VirtualIP
	}else{
		Write-Host "Unable to Create Cluster - $ClusterName"
	}

}



if ($CreateTask -eq $null -or $CreateTask -eq "" -or $CreateTask -match "false" ){
	Write-Host "Skipping Scheduled Task Creation"
}elseif ($CreateTask -match "true"){
	Write-Host "Creating Scheduled Task"
	createSchedTask $ScriptDir
}
