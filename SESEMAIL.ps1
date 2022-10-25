function Send-TestEmail{
    [cmdletbinding()]
    Param (
    [Parameter(Mandatory=$true)]
        [String]$SMTPServer,
    [Parameter(Mandatory=$true)]    
        [String]$Username,
    [Parameter(Mandatory=$true)]    
        [String]$FromEmail,
    [Parameter(Mandatory=$true)]    
        [String]$ToEmail,
    [Parameter(Mandatory=$true)]    
        [int32]$Port
   )
   Process{
        $SecurePassword = Read-Host "Please type the password for $Username" -AsSecureString
        $Credentials = New-Object System.Management.Automation.PsCredential($Username, $SecurePassword)
        $Subject = "SMTP Server Test"
        $Body = "Hello, <br><br> This email message was sent to check the SMTP functionality. Please ignore this message.<br><br> Thank you!" 
        try { 
            Send-MailMessage -From $FromEmail -To $ToEmail -Subject $Subject -Body $Body -Priority High -SmtpServer $SMTPServer -Credential $Credentials -UseSsl -Port $Port -BodyAsHtml -ErrorAction Stop 
            Write-Host "The test email was successfully sent. Please check the inbox of $ToEmail." -ForegroundColor Green 
        } 
        catch { 
            Write-Host "Failed to send the email. Please make sure that the information entered is correct." -ForegroundColor Red 
        }
    } 
}