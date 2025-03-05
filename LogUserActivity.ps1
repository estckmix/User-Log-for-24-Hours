## ===========================================================================
## NAME:        LogUserActivity.ps1
## CREATED:     05-MAR-2025
## BY:          DAVID RADOICIC
## VERSION:     1.0
## DESCRIPTION: Checks the Windows system for all users logged in over the last 24 hours and sends an email.
##
##
## ===========================================================================

# Timezone configuration: Convert to Central Time
try {
    $CTzone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Central Standard Time")
} catch {
    Write-Error "Central Timezone not found on system."
    $CTzone = $null
}
if ($CTzone) {
    $timestamp = [System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), $CTzone)
    $timestampStr = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")
    $tzLabel = "(Central Time)"
} else {
    $timestampStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $tzLabel = "(Local Time)"
}

# Get all logon events (Event ID 4624 = successful login)
$startTime = (Get-Date).AddDays(-1)  # 24 hours ago
$logonEvents = Get-WinEvent -LogName Security -FilterHashtable @{LogName='Security'; Id=4624; StartTime=$startTime} -ErrorAction SilentlyContinue

# Process logon events
$loginRecords = @()
foreach ($event in $logonEvents) {
    $eventXML = [xml]$event.ToXml()
    $timeGenerated = [System.TimeZoneInfo]::ConvertTimeFromUtc($event.TimeCreated.ToUniversalTime(), $CTzone)
    $userName = $eventXML.Event.EventData.Data | Where-Object {$_.Name -eq 'TargetUserName'} | Select-Object -ExpandProperty '#text'
    $logonType = $eventXML.Event.EventData.Data | Where-Object {$_.Name -eq 'LogonType'} | Select-Object -ExpandProperty '#text'

    # Skip system/logon-as-service accounts
    if ($userName -notmatch '^(DWM|UMFD|ANONYMOUS|LOCAL SERVICE|NETWORK SERVICE|SYSTEM)$' -and $userName) {
        $loginRecords += "$($timeGenerated.ToString('yyyy-MM-dd HH:mm:ss')) $tzLabel - User: $userName (Logon Type: $logonType)"
    }
}

# Prepare report content
if ($loginRecords.Count -gt 0) {
    $reportBody = "User Logins in the Last 24 Hours:`n`n" + ($loginRecords -join "`n")
} else {
    $reportBody = "No user logins detected in the last 24 hours."
}

# Email Configuration
$recipientEmail = "YOUR EMAIL HERE"
$subject = "Daily User Login Report - $timestampStr CT"

# Attempt to send via Outlook
$sent = $false
try {
    $Outlook = New-Object -ComObject Outlook.Application
    $Mail = $Outlook.CreateItem(0)
    $Mail.To = $recipientEmail
    $Mail.Subject = $subject
    $Mail.Body = $reportBody
    $Mail.Send()
    $sent = $true
} catch {
    $sent = $false
}

# If Outlook fails, send via SMTP
if (-not $sent) {
    $SMTPServer = "smtp.office365.com"
    $SMTPPort = "587"
    $EmailFrom = "your_hotmail_account@hotmail.com"
    $SMTPUsername = "your_hotmail_account@hotmail.com"
    $SMTPPassword = "YourSecureAppPassword" # Replace with App Password if required

    # Convert password to secure string
    $SecurePassword = ConvertTo-SecureString $SMTPPassword -AsPlainText -Force
    $Credentials = New-Object System.Management.Automation.PSCredential ($SMTPUsername, $SecurePassword)

    # Send email via SMTP
    try {
        Send-MailMessage -From $EmailFrom -To $recipientEmail -Subject $subject -Body $reportBody -SmtpServer $SMTPServer -Credential $Credentials -UseSsl -Port $SMTPPort
        Write-Host "Email Sent Successfully."
    } catch {
        Write-Host "Email failed: $_"
    }
}