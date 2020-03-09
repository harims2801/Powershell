<#
.SYNOPSIS
    DORM_HC_Windows_Server.ps1

.DESCRIPTION
    This Script Performs all the required Server Health Checks and email the result.
	Script is created to monitor application service and application URL and perform the failover actions 

.PARAMETER <Parameter_Name>
  No Parameters

.INPUTS
  Config file with script file name - holds all inputs such as Application Web URL, Service name etc.,
  

.OUTPUTS
  text file will be generated in specified output folder, if o/p folder is not specified in config file then the output file can be placed in Script location

.NOTES
  Script:         Failover Cluster bot
  Author:         Hariharan MS 
  Requirements:   Powershell v4.0, Failover Clustering service and module.
  Creation Date:  06/07/2019
  Modified Date:  09/07/2019
  Remarks      : 

  .History:
		Version	Date				Author				Description        
		0.1		06/07/2019			Hariharan MS		Created Draft version with necessary functionalities
		0.2		09/07/2019			Hariharan MS		Updated Config file and email function.
		1.0		12/07/2019			Hariharan MS		Updated IIS service Validation and Log clearing function
.EXAMPLE
# Script Usage 

 .\Failover_Cluster_bot.ps1

#>


#***************************************|SCRIPT STARTS HERE|***************************************#


# This variable holds the path that the script was run from.
[string]$Global:ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# This variable holds the name of the currently running script.
[string]$Global:ScriptFile = split-path -Leaf $MyInvocation.MyCommand.Definition
# This variable holds the name of the configuration file
[string]$Global:ConfigFile = [io.path]::GetFileNameWithoutExtension("$Global:ScriptPath\$Global:ScriptFile") + ".ini"
$global:ConfigFile = "$Global:ScriptPath\$ConfigFile"
$dat = $(get-date).ToShortDateString()
$log_date = [System.String]::Format("$dat")
$log_date = $log_date.replace("/","-")

[string]$Global:logFile = [io.path]::GetFileNameWithoutExtension("$Global:ScriptPath\$Global:ScriptFile") + ".log"
$global:logFile = "$Global:ScriptPath\$log_date - $logFile"

[string]$Global:outfile = [io.path]::GetFileNameWithoutExtension("$Global:ScriptPath\$Global:ScriptFile") + ".out"
$global:outfile = "$Global:ScriptPath\$outfile"

####################################################################################################
# CheckService - Check if service is Running or not and returns Pass/Fail based on service status
####################################################################################################

function CheckService{

	$Status = $(Get-Service $SrvName).Status

	If ($Status -eq "Running"){

		$SrvStatus = "Pass"

	}else{

		$SrvStatus = "Fail"

	}
	return $SrvStatus
}

#-------------------[End of Function CheckService]--------------------------------------------------

####################################################################################################
# CheckWebUrl - Check if Web URL is Available or not and returns Pass/Fail based on status
####################################################################################################

function CheckWebUrl{

	try{

		$res = Invoke-RestMethod -Uri $appUrl
			if ($res -ne $null){
				$Webstatus = "Pass"
			}
	}
	catch{

		#Url not accessible
		$Webstatus = "Fail"

	}


	return $Webstatus

}

#-------------------[End of Function CheckWebUrl]--------------------------------------------------

####################################################################################################
# WRITING LOG FILE - FOR ALL MESSAGES
####################################################################################################

function Write-Log($text) {

 
    [string]$logMessage = [System.String]::Format("[$(Get-Date)] -"), $text
    Add-Content -Path $logFile -Value $logMessage -Force
}

#------------------------------------------------------------------------------------------#

####################################################################################################
# SENDING MAIL TO RECIPIENTS
####################################################################################################

Function sendEmail()
{
	<#
		.SYNOPSIS
		This functions helps you send emails to the specified recipients list.
		
		.DESCRIPTION
		Use this function to send emails to the specified recipients list.
		
		.PARAMETER  emailSubject
		The email subject will have the full dorm report or healthcheck results
		
		.PARAMETER  emailBody
		The email body will have the full content of the output file or the health check summary results.
		
		.EXAMPLE
		sendEmail $emailSubject $emailBody
	#>

    Param(
    [Parameter(Mandatory=$false)]
    $toAddress,

    [Parameter(Mandatory=$false)]
    $emailSubject,

    [Parameter(Mandatory=$false)]
    $emailBody,
	
	[Parameter(Mandatory=$false)]
    $port

     )
	Write-Log "Sending Email"
	Write-host "Sending Email"
    # Email Content and Attachment
    $Message = New-Object System.Net.Mail.MailMessage
	$Message.IsBodyHTML = $true  
    $Message.From = $EmailFrom
    $Message.To.Add($toAddress)
    $Message.Subject = $(hostname) + " : " + $emailSubject
    $Message.Body = $emailBody
    
    # Send the Report
    if($SmtpServer -ne $null -and $SmtpServer -ne '')
    { #write-host "$SmtpServer,$EmailFrom, $Password"
        $Smtp = New-Object Net.Mail.SmtpClient($SmtpServer,$port)
		#$Smtp.Credentials = New-Object System.Net.NetworkCredential("$EmailFrom", "$Password"); 
	$pass = get-content $passpath | convertto-securestring
	$Smtp.Credentials = new-object -typename system.management.automation.pscredential -argumentlist "haritha.nadegouni@apdcomms.co.uk",$pass
		$smtp.EnableSsl = $true
        $Smtp.Send($Message)
    }
    else
    {
        #write-host "SMTP server looks not configured... Hence stopping mail to send!`n" -ForegroundColor Yellow
        Write-Log "SMTP server looks not configured... Hence stopping mail to send!`n"
    }

	if($?)
	{
		$comment =  "email sent succesfully to $toAddress with the subject $emailSubject`r`n"
        Write-Log "$comment"	
	}
	else {
		$comment =  "email was not sent `r`n"
        Write-Log "$comment"	
	}

} 


####################################################################################################
# Getting Old Active node from the out file
####################################################################################################

Function get_old_ActiveNode{

	if(test-path -Path $outfile) 
	{ 
	
	$old_ActiveNode =Get-Content $outfile | where { $_.contains("Active_node")}
	$old_ActiveNode = $old_ActiveNode.split("=")[1]
	}else{
	$old_ActiveNode = hostname
	}
	#write-host "$outContent"
	Return $old_ActiveNode
}

####################################################################################################
# Creating out file with cluster and application status
####################################################################################################

Function create_outFile($activenode,$App_service_Status,$App_Url_status){
	$last_checkup = [System.String]::Format("$(Get-Date)")

	clear-content -path $outfile
	#write-host "$old_node,$activenode,$App_service_Status,$App_Url_status"
	Add-Content -Path $outfile -Value "#Active Node Health Check details"
	Add-Content -Path $outfile -Value ""
	Add-Content -Path $outfile -Value "Active_node=$activenode"
	Add-Content -Path $outfile -Value "last_healthcheck_time=$last_checkup"
	Add-Content -Path $outfile -Value "App_service_Status=$App_service_Status"
	Add-Content -Path $outfile -Value "App_Url_status=$App_Url_status"
	
}

####################################################################################################
# Clearing old log files
####################################################################################################

Function Clear-logs{
	$files = dir "*failover_cluster_bot.log" | where { $($(get-date) - $($_.CreationTime)).Days -ge $Log_duration}
	
	foreach ($file in $files){
		try{
			remove-item $file
		}catch{
			write-Log "Error Deleting log file $file"
		}
		write-Log "log file - $file has been deleted"
	}
}



Write-Log "Initiating Failover Health Check"

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
try{
import-module FailoverClusters

}
Catch{
    Write-log  "Unable to Import FailoverClusters Module, Exiting Script"
    Exit(0)
}

$comName = hostname

Write-Log "Executing script on $comName"

$ActiveNode = $(get-clusterGroup -Name "Cluster Group").OwnerNode.Name

$old_node = get_old_ActiveNode
if ($comName -eq $ActiveNode){
    #current node is active node verify services
# Verify IIS service and start the service if its not started
	if ($(get-service "W3SVC").status -eq "Running") {
		Write-Log "IIS service status - Pass"	
	}else{
		Write-Log "IIS service status - Fail"
		Write-Log "Starting IIS service"
		get-service "W3SVC" | Start-service
		if ($(get-service "W3SVC").status -eq "Running"){
			Write-Log "IIS service succesfully started"	
		}else{
			Write-Log "IIS service failed to start"
			$emailSubject = "IIS service failed to start on $ActiveNode"
			$Body = "Hi Team, <BR>
			<BR>
			IIS service failed to start on $ActiveNode, Please find details below:<BR><BR>
			Current Active node:$ActiveNode<BR>
			MariaDB service status:$srvStatus<BR>
			Application URL status:$Webstatus<BR>
			IIS service status:Fail<BR>
			old Active node:$old_node<BR>
			<BR>
			Regards,<BR>
			Failover Monitoring Bot<BR>"
			if ($SendEmailReport -match "true")
			{
				sendEmail -toAddress $EmailTo -emailSubject $emailSubject -emailBody $Body -port $port
			}
		}
	}
    $Webstatus = CheckWebUrl
    $srvStatus = CheckService
    Write-Log "Web request status - $Webstatus"
    Write-Log "service status - $srvStatus"
	
	
	if ($ActiveNode -ne $old_node){
		$emailSubject = "Cluster failover to $ActiveNode"
		$Body = "Hi Team, <BR>
		<BR>
		Cluster Failover has been occured, Please find details below:<BR><BR>
		Current Active node:$ActiveNode<BR>
		MariaDB service status:$srvStatus<BR>
		Application URL status:$Webstatus<BR>
		old Active node:$old_node<BR>
		<BR>
		Regards,<BR>
		Failover Monitoring Bot<BR>"
		if ($SendEmailReport -match "true")
		{
			sendEmail -toAddress $EmailTo -emailSubject $emailSubject -emailBody $Body -port $port
		}
	}

	if (($Webstatus -eq "Pass") -and ($srvStatus -eq "Pass")){
	    #Services are available
	Write-Log   "All services are up"
	
	}else{
        Write-Log "Initiating failover"
	#delay failover and stop IIS service
	Write-Log "Stopping IIS service"
	get-service "W3SVC" | Stop-service
	if ($(get-service "W3SVC").status -eq "Running"){
		Write-Log "IIS service failed stop"	
	}else{
		Write-Log "IIS service succesfully stopped"
	}
	Write-Log "Delaying Failover by $failover_delay seconds"
	Start-sleep -s $failover_delay
	Write-Log "Modifying Cluster Active node"

	    #Application services are not available, changing active node
	    $status = Move-ClusterGroup "Cluster Group"
	    $ActiveNode = $(get-clusterGroup -Name "Cluster Group").OwnerNode.Name
		    if ($comName -ne $ActiveNode){
		        #Active Cluster node changed successfully
            Write-Log "Active Cluster node changed successfully"
            #notify cluster admin on failover
			$emailSubject = "Failover Initiated and Active Cluster node changed successfully"
			$Body = "Hi Team, <BR>
			<BR>
			Cluster Failover has been succesfully completed, Please find details below:<BR><BR>
			Current Active node:$ActiveNode<BR>
			MariaDB service status:$srvStatus<BR>
			Application URL status:$Webstatus<BR>
			old Active node:$old_node<BR>
			<BR>
			Regards,<BR>
			Failover Monitoring Bot<BR>"
				if ($SendEmailReport -match "true")
				{
					sendEmail -toAddress $EmailTo -emailSubject $emailSubject -emailBody $Body -port $port
				}
		    }else{
		        #Active Cluster node not modified
		    Write-Log "Failover Initiated but failed to modify active node"
			$emailSubject = "Error in Changing Active node status..!!"
			$Body = "Hi Team, <BR>
			<BR>
			Cluster Failover has been initiated but failed to complete, Please find details below:<BR><BR>
			Current Active node:$ActiveNode<BR>
			MariaDB service status:$srvStatus<BR>
			Application URL status:$Webstatus<BR>
			old Active node:$old_node<BR>
			<BR>
			Regards,<BR>
			Failover Monitoring Bot<BR>"
				if ($SendEmailReport -match "true")
				{
					sendEmail -toAddress $EmailTo -emailSubject $emailSubject -emailBody $Body -port $port
				}
		    }
	}
	create_outFile $ActiveNode $srvStatus $Webstatus
}else{
	#Current node is not active node	
	Write-Log "Current node is not active node"
	# Verify IIS service and stop the service if its not stopped
	if ($(get-service "W3SVC").status -eq "Running") {
		Write-Log "IIS service status - Running"	
		Write-Log "Stopping IIS service"
		get-service "W3SVC" | Stop-service
		if ($(get-service "W3SVC").status -eq "Running"){
			Write-Log "IIS service failed to stop"	
			$emailSubject = "IIS service failed to stop on $comName"
			$Body = "Hi Team, <BR>
			<BR>
			IIS service failed to start on $comName, Please find details below:<BR><BR>
			Current Active node:$ActiveNode<BR>
			MariaDB service status:$srvStatus<BR>
			Application URL status:$Webstatus<BR>
			IIS service status:Running<BR>
			old Active node:$old_node<BR>
			<BR>
			Regards,<BR>
			Failover Monitoring Bot<BR>"
			if ($SendEmailReport -match "true")
			{
				sendEmail -toAddress $EmailTo -emailSubject $emailSubject -emailBody $Body -port $port
			}
		}else{
			Write-Log "IIS service succesfully stopped"	
		}
	}else{
		Write-Log "IIS service status - Stopped"
	}
	create_outFile $ActiveNode $srvStatus $Webstatus
}

Write-Log "Checking for old log files"
Clear-logs

#cleanup

$status = $null
$ActiveNode = $null
$srvStatus = $null
$Webstatus = $null
$old_node = $null

Write-Log "Failover health Check completed"
