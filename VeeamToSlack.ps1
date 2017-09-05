##########################################################################################
#                                                                                        #
#    Veeam Agent for Windows : Notification on Slack                                     #
#    Script forked from Veeam community, special thanks to @RamblingCookieMonster        # 
#                                                                                        #
#                                                   @NK74 (aka Valentin Parmeland)       #
##########################################################################################

# CUSTOMISATION BELLOW
$TokenSlack = "YOUR SLACK TOKEN"
$NomClient = "MESSAGE NAME"
$ChannelSlack = "YOUR CHANNEL NAME"


$OS = gwmi win32_operatingsystem | % caption
$hostname = hostname
$TimeGenerated   =get-eventlog "Veeam Agent" -newest 1 -entrytype Information, Warning, Error -source "Veeam Agent" | Format-Wide -property TimeGenerated | out-string
$TimeBackupStarted   =get-eventlog "Veeam Agent" -InstanceID 110 -newest 1 -entrytype Information, Warning, Error -source "Veeam Agent" | Format-Wide -property TimeGenerated | out-string
$Source      =get-eventlog "Veeam Agent" -newest 1 -entrytype Information, Warning, Error -source "Veeam Agent" | Format-List -property Source | out-string
$EntryType   =get-eventlog "Veeam Agent" -newest 1 -entrytype Information, Warning, Error -source "Veeam Agent" | Format-List -property EntryType | out-string
$Message   =get-eventlog "Veeam Agent" -newest 1 -entrytype Information, Warning, Error -source "Veeam Agent" | Format-Wide -property Message -AutoSize | out-string
$InstanceID   =get-eventlog "Veeam Agent" -newest 1 -entrytype Information, Warning, Error -source "Veeam Agent" | Format-List -property InstanceID| out-string
$date = Get-Date -format F
$difference = (new-timespan -Start $TimeBackupStarted -End $TimeGenerated)
$duration = "{0:c}" -f $difference
$TimeGenerated = [datetime]::parse($TimeGenerated)
$TimeBackupStarted = [datetime]::parse($TimeBackupStarted)
$start = "{0:HH:mm:ss}" -f $TimeBackupStarted
$end = "{0:HH:mm:ss}" -f $TimeGenerated
$mb = " Mo"
$gb = " Go"
$tb = " To"
$key = "hklm:\SOFTWARE\Veeam\Veeam Endpoint Backup\DbConfiguration"
$User = (get-Item $key).GetValue("SqlLogin")
$Pass = (get-Item $key).GetValue("SqlPassword")
$dbServer = (get-Item $key).GetValue("SqlInstancePipeName")
$db = (get-Item $key).GetValue("SqlDatabaseName")
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=$dbServer;Database=$db;uid=$User;password=$Pass;"
$QueryStored = "SELECT TOP 1 stored_size FROM [VeeamBackup].[dbo].[ReportSessionView] ORDER BY [creation_time] DESC"
$SqlCmdStored = New-Object System.Data.SqlClient.SqlCommand
$SqlCmdStored.CommandText = $QueryStored
$SqlCmdStored.Connection = $SqlConnection
$SqlAdapterStored = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapterStored.SelectCommand = $SqlCmdStored
$DataSetStored = New-Object System.Data.DataSet
$SqlAdapterStored.Fill($DataSetStored)
$QueryDiskspace = "SELECT [free_space] FROM [VeeamBackup].[dbo].[BackupRepositories] WHERE (name = 'Shared folder')"
$SqlCmdDiskspace = New-Object System.Data.SqlClient.SqlCommand
$SqlCmdDiskspace.CommandText = $QueryDiskspace
$SqlCmdDiskspace.Connection = $SqlConnection
$SqlAdapterDiskspace = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapterDiskspace.SelectCommand = $SqlCmdDiskspace
$DataSetDiskspace = New-Object System.Data.DataSet
$SqlAdapterDiskspace.Fill($DataSetDiskspace)
$QueryBackupsize = "SELECT TOP 1 total_backed_up_size FROM [VeeamBackup].[dbo].[WmiServer.JobSessionsView] ORDER BY creation_time DESC"
$SqlCmdBackupsize = New-Object System.Data.SqlClient.SqlCommand
$SqlCmdBackupsize.CommandText = $QueryBackupsize
$SqlCmdBackupsize.Connection = $SqlConnection
$SqlAdapterBackupsize = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapterBackupsize.SelectCommand = $SqlCmdBackupsize
$DataSetBackupsize = New-Object System.Data.DataSet
$SqlAdapterBackupsize.Fill($DataSetBackupsize)
$QueryMessage = "SELECT TOP 1 reason AS Reason, stop_details AS Detail FROM [VeeamBackup].[dbo].[Backup.Model.JobSessions] ORDER BY creation_time DESC"
$SqlCmdMessage = New-Object System.Data.SqlClient.SqlCommand
$SqlCmdMessage.CommandText = $QueryMessage
$SqlCmdMessage.Connection = $SqlConnection
$SqlAdapterMessage = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapterMessage.SelectCommand = $SqlCmdMessage
$DataSetMessage = New-Object System.Data.DataSet
$SqlAdapterMessage.Fill($DataSetMessage)
$SqlConnection.Close()
[int64]$space_backup = $DataSetStored.Tables[0] | Format-Wide -AutoSize | out-string
[int64]$space_free = $DataSetDiskspace.Tables[0] | Format-Wide -AutoSize | out-string
[int64]$space_all = $DataSetBackupsize.Tables[0] | Format-Wide -AutoSize | out-string
$reason = $DataSetMessage.Tables[0] | Format-Table -HideTableHeaders -Property Reason -wrap | out-string
$detail = $DataSetMessage.Tables[0] | Format-Table -HideTableHeaders -Property Detail -wrap | out-string
if(!$_.reason)
{$reason = $Message}
if($space_backup -ge 1048576 -and $space_backup -lt 1073741824)
{$spacebackup = "{0:n2}" -f ($space_backup /1048576) + $mb}
elseif($space_backup -ge 1073741824 -and $space_backup -lt 1099511627776)
{$spacebackup = "{0:n2}" -f ($space_backup /1073741824) + $gb}
elseif($space_backup -ge 1099511627776)
{$spacebackup = "{0:n2}" -f ($space_backup /1099511627776) + $tb}
else
{$spacebackup = ("0" + $mb)}
if($space_free -ge 1048576 -and $space_free -lt 1073741824)
{$spacefree = "{0:n2}" -f ($space_free /1048576) + $mb}
elseif($space_free -ge 1073741824 -and $space_free -lt 1099511627776)
{$spacefree = "{0:n2}" -f ($space_free /1073741824) + $gb}
elseif($space_free -ge 1099511627776)
{$spacefree = "{0:n2}" -f ($space_free /1099511627776) + $tb}
else
{$spacefree = ("0" + $mb)}
if($space_all -ge 1048576 -and $space_all -lt 1073741824)
{$spaceall = "{0:n2}" -f ($space_all /1048576) + $mb}
elseif($space_all -ge 1073741824 -and $space_all -lt 1099511627776)
{$spaceall = "{0:n2}" -f ($space_all /1073741824) + $gb}
elseif($space_all -ge 1099511627776)
{$spaceall = "{0:n2}" -f ($space_all /1099511627776) + $tb}
else
{$spaceall = ("0" + $mb)}

if ($Message.contains("Success")) {
   $bgcolor = "#00B050"
   $backupState = "SUCCESS"
} 
elseif ($Message.contains("Warning")){
   $bgcolor = "#ffd96c"
   $backupState = "WARNING"
}
elseif ($Message.contains("Failed","Error")){   
   $bgcolor = "#fb9895"
   $backupState = "ERROR"
}

$A = "Backup status"
$B = "Backup size"
$C = "Start at"
$D = "End at"
$E = "Diskspace on destination"

$Fields = [pscustomobject]@{
    $A = $backupState
    $B = $spaceall
    $C = $start
    $D = $end
    $E = $spacefree
} | New-SlackField -Short

New-SlackMessageAttachment -Title 'Log file veeam' `
                           -AuthorName $hostname `
                           -AuthorIcon 'https://maxcdn.icons8.com/Share/icon/color/Logos//veeam1600.png' `
                           -Color $bgcolor `
                           -Fields $Fields `
                           -Fallback 'Veeam Agent For Windows' `
                           -Text $reason |                         
New-SlackMessage -Channel $ChannelSlack `
                     -AsUser `
                     -Username $NomClient |
Send-SlackMessage -Uri $TokenSlack
