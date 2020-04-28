$logFile = "c:\temp\Logs.txt" 

function Write-Log($text) {

 
    [string]$logMessage = [System.String]::Format("[$(Get-Date)] -"), $text
    Add-Content -Path $logFile -Value $logMessage -Force
}

Write-Log "Append text to log file"



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
