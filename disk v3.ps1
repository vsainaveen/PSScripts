<#
  .SYNOPSIS
  Retrieves logical disk used information from one or more computers.

  .DESCRIPTION
  Script displays each disk's drive letter, used percentage and send an email to intended recipients

  .PARAMETER Input
  The computer name or IP should be updated in input.csv.

  .INPUTS
  Update all parameters in input.csv file. e.g., SERVER1

  .OUTPUTS
  One html file will generate diskutilization.htm. All drives info in one field and comments field will get upadated if the server is not reachable or failed to get details.

  .EXAMPLE
  .\disk.ps1

  .LINK
  https://github.com/vsainaveen/PSScripts

  .NOTES
  AUTHOR  : SAI NAVEEN VANAPALLI
  CREATED : 06-05-2020
  VERSION : 3.0
#>


$input=Import-csv "$PSScriptRoot\Input.csv"
$servers= $input.servers
$attachment="$PSScriptRoot\diskutilization $(Get-Date -f 'ddMMyy').htm"

$msg=@"
<html>
    <style>
        h1{text-align:center}
        th{background-color:cyan}
        table, td, th {
            border: 2px solid black;
            border-collapse: collapse;
        }
    </style>
    <h1>Disk Utilization Report</h1><br>
    <table>
        <thead>
            <th>SERVER</th>
            <th>DRIVE %USED</th>
            <th>COMMENTS</th>
        </thead>
"@


foreach($server in $servers){
    $output=[pscustomobject][ordered]@{Server=$server;Drive=$null;Comments=$null}
    try{
        $disks=$null
        $disks=get-wmiobject -Class win32_logicaldisk -computername $server -ErrorAction Stop
        $output.Drive=$($disks | where{$_.size -ne 0 -and $_.size -ne $null} | %{"$($_.deviceid) $([math]::round((($_.size-$_.freespace)/$_.size)*100,2))%<br>"})
        }
    catch{$output.comments=$_.exception.message}
    $msg+="
    <tr>
    <td>$($output.server)</td>
    <td>$($output.drive)</td>
    <td>$($output.comments)</td>
    </tr>
    "
    $output.drive=$output.drive.replace('<br>',"`n");$output.drive=$output.drive.replace(' ',"`t");$output |fl

}
$msg+="</table></html>"

$msg | Out-File $attachment -Force