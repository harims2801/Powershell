$logFile = "c:\temp\Logs.txt"

function Write-Log($text) {

 
    [string]$logMessage = [System.String]::Format("[$(Get-Date)] -"), $text
    Add-Content -Path $logFile -Value $logMessage -Force
}

Write-Log "Append text to log file"
