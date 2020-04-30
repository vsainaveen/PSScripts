<#
  .SYNOPSIS
  Retrieves logical disk used information from one or more computers.

  .DESCRIPTION
  Script displays each disk's drive letter, used percentage and send an email to intended recipients

  .PARAMETER Input
  The computer name, or names, Sender, Recipients and Smtpserver fields should be updated in input.csv. NOTE- Except servers field, rest all should declare in first row. Also, multiple recipients must be declared with ';' seperation in a single line.

  .INPUTS
  None. You cannot pipe objects to Update-Month.ps1.

  .OUTPUTS
  None. Update-Month.ps1 does not generate any output.

  .EXAMPLE
  .\disk.ps1 #csv - SERVER1,a@abc.com,a@abc.com;b@abc.com,smtp.abc.com

  .NOTES
  AUTHOR  -SAI NAVEEN VANAPALLI
  CREATED -30-04-2020
  VERSION -1.0
#>


$input=Import-csv Input.csv
$servers= $input.servers

$from=$input.sender
$to=$input.recipients.split(';')
$smtpserver=$input.smtpserver
$tstamp=$(Get-Date -f 'dd-MM-yy HH:mm')
$subject="Disk Utilization Report $tstamp"
$body="Hello Team,`n`nPlease find the attached disk utilization report.`n`n`nThanks"
$attachment='diskutilization.csv'

foreach($server in $servers){
    $output=[pscustomobject][ordered]@{Server=$server;Drive='-';Comments=$null}
    try{
        $disks=$null
        $disks=get-wmiobject -Class win32_logicaldisk -computername $server -ErrorAction Stop
        $output.Drive=$($disks | %{"$($_.deviceid) $([math]::round((($_.size-$_.freespace)/$_.size)*100,2))%`n"})
        }
    catch{$output.comments='not reachable'}
    $output;$output | export-csv $attachment -NoTypeInformation -Append
}

try{
    Send-MailMessage -From $input -To $to -Subject $subject -Body $body -Attachments $attachment -SmtpServer $smtpserver -ErrorAction Stop
}
catch{Write-Host "Failed to send email. $($_.exception.message)" -BackgroundColor Red -ForegroundColor White}
