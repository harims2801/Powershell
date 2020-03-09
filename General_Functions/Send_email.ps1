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
