# User-Log-for-24-Hours


PowerShell script that tracks all user logins over the last 24 hours and sends a human-readable report via email.
________________________________________
How the Script Works
1.	Extracts Login History: Uses Get-WinEvent to pull logon events from the Windows Event Log (Event ID 4624 for successful logins).
2.	Filters Past 24 Hours: Filters for logins within the last 24 hours.
3.	Formats Data: Converts event details into a human-readable report.
4.	Sends Email: Uses either Outlook COM (if available) or SMTP (if Outlook isn’t set up).
5.	Runs Daily: Can be scheduled in Task Scheduler to run every 24 hours.

Explanation of the Script

•	Event Log Filtering: Extracts Windows Event ID 4624 (successful logins).

•	Filtering for the Last 24 Hours: Filters logins from (Get-Date).AddDays(-1).

•	User Account Filtering: Removes system/service accounts (e.g., SYSTEM, NETWORK SERVICE, etc.).

•	Logon Type Included: Helps differentiate local vs. remote logins.

•	Email Sending: 

•	Tries Outlook first (if available).

•	Falls back to SMTP if Outlook isn’t configured.
________________________________________
How to Schedule the Script in Task Scheduler
To run this script every 24 hours, follow these steps:

1.	Save the script to a file, e.g., C:\Scripts\LogUserActivity.ps1.

2.	Open Task Scheduler (taskschd.msc).

3.	Create a New Task: 
•	Name: Daily User Login Report
•	Set to Run whether user is logged on or not.

4.	Set the Trigger: 
•	Click New > Begin the task On a schedule.
•	Set Daily and pick a time (e.g., 12:00 AM).
•	Ensure Repeat every: 24 hours is selected.

5.	Set the Action: 
•	Click New > Action: Start a Program.
•	Program/script: powershell.exe
•	Arguments: 
•	-ExecutionPolicy Bypass -File "C:\Scripts\LogUserActivity.ps1"

6.	Save and Test: 
•	Click OK, enter credentials (if needed).
•	Right-click the task and Run to test it.
