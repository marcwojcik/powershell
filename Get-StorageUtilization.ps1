#region ******** SCRIPT INFORMATION                     ********

# Script Name:		VMware_VM_Storage_Utilization.ps1
# Date Created:		02-April-2014
# Author:	

# Version History:	
#					1.0 - 02-April-2014 - Initial script

# Details:			Script used in conjunction with the 'VMWARE.VIMAUTOMATION.CORE' snap-in
#					to determine the VM storage utilization.

#endregion ******** SCRIPT INFORMATION                  ********

# Continue processing on error
$ErrorActionPreference = "SilentlyContinue"

#region #******** INPUTS                                ********

$myVCenter = "vcenter-prod"

#endregion #******** INPUTS                             ********

#region ---- Load the 'VMWARE.VIMAUTOMATION.CORE' snap-in    ----

$snpVIM = 'VMWARE.VIMAUTOMATION.CORE'

# Determine if the 'VMWARE.VIMAUTOMATION.CORE' snap-in is already loaded
$bolVIM = gsnp $snpVIM

# If not loaded, add the snap-in
if (!$bolVIM) {
	asnp $snpVIM
	$bolVIM = $null
	
	# Test to see if the snap-in was loaded successfully
	$bolVIM = gsnp $snpVIM
	if (!$bolVIM) {
		# The snap-in was not loaded successfully... exit the script
		Exit
	}
	else {
		# The snap-in was loaded... continue the script
	}
}

#endregion ---- Load the 'VMWARE.VIMAUTOMATION.CORE' snap-in ----

#region #******** VARIABLES                             ********

$startTime = Get-Date
$myScriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path
$thisReportDate = Get-Date -Format s
$myCreds = Get-VICredentialStoreItem -File "$($myScriptLocation)\creds.xml"
$objMetrics = "disk.numberwrite.summation","disk.numberread.summation"

#endregion #******** VARIABLES                          ********

#region #******** MAIN CODE - BEGIN PROCESSING          ********

#region ---- Connect to the specified vCenter                ----

# Connect to the vCenter using the provided location, username and password
#$thisConnection = Connect-VIServer -Server $myVCenter -Protocol https -User $myVCenterUser -Password $myVCenterPassword
$thisConnection = Connect-VIServer -Server $myCreds.Host -Protocol https -User $myCreds.User -Password $myCreds.Password

if ($? -and $thisConnection) {
	# The connection was successful
}
else {
	# The connection was not successful
	Exit
}

#endregion ---- Connect to the specified vCenter             ----

#region ---- Get Datastore Information                       ----

. $myScriptLocation\out-datatable.ps1
. $myScriptLocation\write-datatable.ps1

$thisReport = ForEach ($vm in Get-VM) { $vm.ExtensionData.Guest.Disk | 
    Select `
        @{N="vm_name";E={$VM.Name}}, `
        @{N="disk_path";E={$_.DiskPath}}, `
        @{N="capacity_mb";E={[math]::Round($_.Capacity/ 1MB)}}, `
        @{N="free_space_mb";E={[math]::Round($_.FreeSpace / 1MB)}}, `
        @{N="free_space_per";E={[math]::Round(((100* ($_.FreeSpace))/ ($_.Capacity)),0)}}, `
        @{N="used_space_mb";E={[math]::Round((($_.Capacity/1MB)) - ($_.FreeSpace/1MB))}}, `
        @{N="used_space_per";E={[math]::Round(100* (($_.Capacity/1MB)-($_.FreeSpace/1MB)) / ($_.Capacity/1MB))}},`
        @{N="date";E={$thisReportDate}},`
        @{N="vcenter";E={$myVCenter}}
} 

$c = $thisReport | Out-DataTable 

Write-DataTable -ServerInstance "SERVERNAME,port" -Database "DATABASE" -TableName "dbo.vm_disk_utilization" -Data $c -Username "Username" -Password "Password"

#endregion ---- Get Datastore Information                    ----

# Reset processing on error
$ErrorActionPreference = "Continue"

# Record the amount of time the script took to execute
$endTime = Get-Date

$timeDiff = New-TimeSpan $startTime $endTime
Write-Host $timeDiff

#endregion #******** MAIN CODE - BEGIN PROCESSING       ********
