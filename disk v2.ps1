<#
  .SYNOPSIS
  Retrieves logical disk used information from one or more computers.

  .DESCRIPTION
  Script displays each disk's drive letter, used percentage and send an email to intended recipients

  .PARAMETER Input
  The computer name, or names, Sender, Recipients and Smtpserver fields should be updated in input.csv. NOTE- Except servers field, rest all should declare in first row. Also, multiple recipients must be declared with ';' seperation in a single line.

  .INPUTS
  Update all parameters in input.csv file. e.g., SERVER1,a@abc.com,a@abc.com;b@abc.com,smtp.abc.com

  .OUTPUTS
  One CSV file will generate diskutilization.csv. All drives info in one field and comments field will get upadated if the server is not reachable or failed to get details.

  .EXAMPLE
  .\disk.ps1

  .LINK
  https://github.com/vsainaveen/PSScripts

  .NOTES
  AUTHOR  : SAI NAVEEN VANAPALLI
  CREATED : 30-04-2020
  VERSION : 2.0
#>



$input=Import-csv Input.csv
$servers= $input.servers
$drives='C:','E:','G:','J:','I:'
$from=$input.sender
$to=$input.recipients.split(';')
$smtpserver=$input.smtpserver
$tstamp=$(Get-Date -f 'dd-MM-yy HH:mm')
$subject="Disk Utilization Report $tstamp"
$body="Hello Team,`n`nPlease find the attached disk utilization report.`n`n`nThanks"
$attachment='diskutilization.csv'

foreach($server in $servers){
    $output=[pscustomobject][ordered]@{Server=$server;'C:'='-';'E:'='-';'G:'='-';'J:'='-';'I:'='-';Comments=$null}
    try{
        $disks=$null
        $disks=get-wmiobject -Class win32_logicaldisk -computername $server -ErrorAction Stop
        $disks | %{$drive=$_.deviceid;$used=$([math]::round((($_.size-$_.freespace)/$_.size)*100,2));if($drives -contains $drive){$output.$drive="$used %"}else{$output.Comments="$drive $used %`t"}}
    }
    catch{$output.comments='not reachable'}
    $output;$output | export-csv $attachment -NoTypeInformation -Append
    }

try{
    Send-MailMessage -From $input -To $to -Subject $subject -Body $body -Attachments $attachment -SmtpServer $smtpserver -ErrorAction Stop
}
catch{Write-Host "Failed to send email. $($_.exception.message)" -BackgroundColor Red -ForegroundColor White}