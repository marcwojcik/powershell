#######################
#VM Environment Report#
#######################

Add-PSsnapin VMware.VimAutomation.Core
Initialize-VIToolkitEnvironment.ps1
connect-VIServer VCenter -User USERNAME -Password PASSWORD 

#Output File Name
$outputFile = 'F:\Internet\wwwroot\VMware\Reports\vCenterReport.html'

#TimeStamp for calculating total run time.
$start = Get-Date;

#Supress Error Messages
$erroractionpreference = "SilentlyContinue";

#Status Message
"Generating Reports..."

#Open Output HTML
"<pre>" > $outputFile;

"VM Environment Report: " + (Get-Date) >> $outputFile;
"" >> $outputFile;
"" >> $outputFile;

#Status Message
"Cluster Resources..."

#Resource Usage By Cluster

foreach ($c in get-cluster | sort-object `
@{expression={$_.name};ascending=$true}) `
{'==================== ' + $c.name + ' ====================' >> $outputFile; `
#Cluster-Wide Stats (CPU & Mem)
($c | select `
@{name='Cluster CPU Average %';expression={"{0,21:#.00}" -f ($_ | get-vmhost | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}}, `
@{name='Cluster Mem Average %';expression={"{0,21:#.00}" -f ($_ | get-vmhost | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> $outputFile; `
#Individual Host Stats (CPU & Mem)
($c | get-vmhost | sort-object @{expression={$_.name};ascending=$true} | `
select name, `
@{name='Host CPU Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}}, `
@{name='Host Mem Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> $outputFile; `

#Total Hosts
($c | select `
@{name='Total Hosts';expression={"{0,11:#}" -f ((($c | get-vmhost | `
where-object {$c | `
get-vmhost}).count))}}, `
#Total VMs (Powered On VM's Only)
@{name='Total VMs';expression={"{0,9:#}" -f ((($c | get-vm | `
where-object {$_.powerstate -eq "PoweredOn"}).count))}}, `
#VM to ESX Host Ratio (Powered On VM's Only)
@{name='VMs per Host';expression={"{0,12:#}" -f ((($c | get-vm | `
where-object {$_.powerstate -eq "PoweredOn"}).count) / (($c | `
get-vmhost).count))}} `
) >> $outputFile; `
#Total Migrations
($c | select `
@{name='Total Migrations';expression={"{0,16:#}" -f ( $c | Get-View).Summary.NumVmotions}} `
) >> $outputFile;  `
#Current Failover Level
($c | select `
@{name='Current Failover Capacity';expression={"{0,16:#}" -f ( $c | Get-View).Summary.CurrentFailoverLevel}} `
) >> $outputFile; `

#Blank spaces between clusters
"" >> $outputFile; `
"" >> $outputFile; `
"" >> $outputFile; `
};

#Status Message
"Datastore Overview..."

#Datastore Overview. Total Capacity, Free Space, Used Space, Space used by Powered Off VM's.

"Datacenter Datastore Overview:" >> $outputFile;

(get-datacenter | select name, `
@{name='Total Capacity(TB)';expression={"{0,18:#.00}" -f ((get-datastore | `
Measure-Object -Sum -Property capacitymb).sum/1mb)}}, `
@{name='Free Space(TB)';expression={"{0,14:#.00}" -f ((get-datastore | `
Measure-Object -Sum -Property freespacemb).sum/1mb)}}, `
@{name='Total Used(TB)';expression={"{0,14:#.00}" -f (`
(((get-datastore | Measure-Object -sum -Property capacitymb).sum/1mb)`
 - ((get-datastore | Measure-Object -sum -Property freespacemb).sum/1mb))`
)}}) >> $outputFile;
"" >> $outputFile;
"" >> $outputFile;

#Datastore Usage (% Used)
get-datastore | sort-object @{expression={$_.name};ascending=$true} | `
select name, `
@{name='% Used';expression={"{0,6:#.00}" -f `
((($_.capacitymb - $_.freespacemb)/$_.capacitymb) * 100)}} `
>> $outputFile;
"" >> $outputFile;
"" >> $outputFile;

#Status Message
"Generating Hotlist..."

#This section creates a hotlist.txt report for VM's and Hosts that are 
#running "hot".
#This also includes Datastores that are nearly full.
"VM Environment Utilzation Report: " >> $outputFile;
"" >> $outputFile;
"" >> $outputFile;

#Status Message
"  VMs..."

#VM's that average over 70% memory usage.
"Virtual Machines Over 70% Average Memory Usage:" >> $outputFile;

(get-vm | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | get-stat -mem -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -ge 70} | select name, memorymb, `
@{name='VM Mem Usage %';expression={"{0,9:#.00}" -f (($_ | `
get-stat -mem -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average)}} `
) >> $outputFile;
"" >> $outputFile;

#VM's that average over 70% cpu usage.
"Virtual Machines Over 70% Average CPU Usage:" >> $outputFile;

(get-vm | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | get-stat -cpu.usagemhz.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -ge 70} | select name, memorymb, `
@{name='VM CPU Usage %';expression={"{0,9:#.00}" -f (($_ | `
get-stat -cpu.usagemhz.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average)}} `
) >> $outputFile;
"" >> $outputFile;

#VM's that average under 5% memory usage.
"Virtual Machines Under 5% Average Memory Usage:" >> $outputFile;

(get-vm | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | get-stat -mem -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -le 5} | select name, memorymb, `
@{name='VM Mem Usage %';expression={"{0,9:#.00}" -f (($_ | `
get-stat -mem -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average)}} `
) >> $outputFile;
"" >> $outputFile;

#VM's that average under 5% cpu usage.
#"Virtual Machines Under 5% Average CPU Usage:" >> $outputFile;

#(get-vm | sort-object @{expression={$_.name};ascending=$true} | `
#Where-Object {($_ | get-stat -cpu.usagemhz.average -intervalmin 120 -maxsamples 360 | `
#Measure-Object value -ave).average -le 5} | select name, memorymb, `
#@{name='VM CPU Usage %';expression={"{0,9:#.00}" -f (($_ | `
#get-stat -cpu.usagemhz.average -intervalmin 120 -maxsamples 360 | `
#Measure-Object value -ave).average)}} `
#) >> $outputFile;
#"" >> $outputFile;

#VM's that average over 95% cpu ready.
"Virtual Machines Over 95% Average CPU Ready:" >> $outputFile;

(get-vm | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | get-stat -cpu.ready.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -ge 95} | select name, memorymb, `
@{name='VM CPU Usage %';expression={"{0,9:#.00}" -f (($_ | `
get-stat -cpu.usagemhz.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average)}} `
) >> $outputFile;
"" >> $outputFile;

#Status Message
"  Hosts..."

#Hosts that average over 70% memory usage.
"ESX Hosts Over 70% Average Memory Usage:" >> $outputFile;

(get-vmhost | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -ge 70} | select name, `
@{name='Host Mem Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat mem.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> $outputFile;
"" >> $outputFile;

#Hosts that average over 70% cpu usage.
"ESX Hosts Over 70% Average CPU Usage:" >> $outputFile;

(get-vmhost | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {($_ | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
Measure-Object value -ave).average -ge 70} | select name, `
@{name='Host CPU Average %';expression={"{0,18:#.00}" -f ($_ | `
get-stat -stat cpu.usage.average -intervalmin 120 -maxsamples 360 | `
measure-object value -ave).average}} `
) >> $outputFile;
"" >> $outputFile;

#Status Message
"  Datastores..."

#Datastores with less than 5% free.
"Datastores with less than 5% free:" >> $outputFile;

(get-datastore | sort-object @{expression={$_.name};ascending=$true} | `
Where-Object {(($_.freespacemb / $_.capacitymb) * 100) -le 5} | select name, `
@{name='% Used';expression={"{0,6:#.00}" -f `
((($_.capacitymb - $_.freespacemb)/$_.capacitymb) * 100)}}`
) >> $outputFile;
"" >> $outputFile;

#Status Message
"Checking ESX Logs..."

#This section will dump ESX vmkwarning messages since the previous day.
"ESX Hosts VMKWarnings since " + `
(get-date (Get-Date).AddDays(-1) -f MMMdd) + ":" >> $outputFile;

foreach ($h in get-vmhost -server $vcserver | `
sort-object @{expression={$_.name};ascending=$true}) `
{(get-log -host $h vmkwarning).entries | `
select-string -pattern ( `
("{0,0} {1,2}" -f (get-date (Get-Date).AddDays(-1) -f MMM), `
(get-date (Get-Date).AddDays(-1) -f %d)) `
-or ("{0,0} {1,2}" -f (get-date -f MMM),(get-date -f %d))) `
>> $outputFile `
};
"" >> $outputFile;
"" >> $outputFile;

#Status Message
"Report Completed in " + ("{0,2:#.00}" -f `
((Get-Date).Subtract($start).totalminutes)) + " Minutes." >> $outputFile;

#Close Output HTML
"</pre>" >> $outputFile;

##################
# Mail variables #
##################
$enablemail="no"
$smtpServer = "" 
$mailfrom = ""
$mailto = ""

if ($enablemail -match "yes") 
{ 
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($outputFile)
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$msg.From = $mailfrom
$msg.To.Add($mailto) 
$msg.Subject = “Dev/Prod - VM Environment Report - $start”
$msg.Body = "Dev/Prod - VM Environment Report - $start"
$msg.Attachments.Add($att) 
$smtp.Send($msg)
}

#Disconnect From VI
Disconnect-VIServer -Confirm:$False
