#=====================================================================================================
# AUTHOR:	Dieter Wijckmans (Dieter.Wijckmans@inovativ.be)
# DATE:		03/08/2012
# Name:		Export-Overrides2012.PS1
# Version:	1.0
# COMMENT:	Export all your overrides to a CSV file to keep for your reference.
#			Based on script of Daniele Muscetta and Pete Zerger
#			http://www.systemcentercentral.com/BlogDetails/tabid/143/IndexID/78323/Default.aspx
# 
# Usage:	.\Export-Overrides2012.ps1 
#
#=====================================================================================================


##Read out the Management server name
$objCompSys = Get-WmiObject win32_computersystem 
$inputScomMS = $objCompSys.name


#Initializing the Ops Mgr 2012 Powershell provider#
Import-Module -Name "OperationsManager" 
New-SCManagementGroupConnection -ComputerName $inputScomMS  


#Set Culture Info# In this case Dutch Belgium
$cultureInfo = [System.Globalization.CultureInfo]'nl-BE'

#Error handling setup
$error.clear()
$erroractionpreference = "SilentlyContinue"
$thisScript = $myInvocation.MyCommand.Path
$scriptRoot = Split-Path(Resolve-Path $thisScript)
$errorLogFile = Join-Path $scriptRoot "error.log"
if (Test-Path $errorLogFile) {Remove-Item $errorLogFile -Force}

#Define the backup location

#Get date 
$Backupdatetemp = Get-Date
$Backupdatetemplocal = ($Backupdatetemp).tolocaltime()
$Backupdate = $Backupdatetemplocal.ToShortDateString()
$strBackupdate = $Backupdate.ToString()

#Define backup location
$locationroot = "C:\backup\SCOM\overridesexport\"
if((test-path $locationroot) -eq $false) { mkdir $locationroot }
$locationfolder = $strbackupdate -Replace "/","-"
$location = $locationroot + $locationfolder + "\"
new-item "$location" -type directory -force

#Delete backup location older than 15 days
#To make sure our disk will not be cluttered with old backups we'll keep 15 days of backup locations.
$Retentionperiod = "15"
$folders = dir $locationroot 
echo $folders
$now = [System.DateTime]::Now 
$old = $now.AddDays("-$Retentionperiod") 

foreach($folder in $folders) 
{ 
   if($folder.CreationTime -lt $old) { Remove-Item $folder.FullName -recurse } 
}

#gets all UNSEALED MAnagement PAcks
 $mps = get-SCOMmanagementpack | where {$_.Sealed -eq $false}
 
#loops thru them
 foreach ($mp in $mps)
 {
     $mpname = $mp.name
     Write-Host "Exporting Overrides info for Management Pack: $mpname"
     
    #array to hold all overrides for this MP
     $MPRows = @()
 
    #Gets the actual override objects
     $overrides = $mp.GetOverrides()
 
    #loops thru those overrides in order to extract information from them
     foreach ($override in $overrides)
     {
 
        #Prepares an object to hold the result
         $obj = new-object System.Management.Automation.PSObject
         
        #clear up variables from previous cycles.
         $overrideName = $null
         $overrideProperty = $null
         $overrideValue = $null
         $overrideContext = $null
         $overrideContextInstance = $null
         $overrideRuleMonitor = $null
 
        # give proper values to variables for this cycle. this is what we can then output.
         $overrideName = $override.Name
         $overrideProperty = $override.Property
         $overrideValue = $override.Value
         trap { $overrideContext = ""; continue } $overrideContext = $override.Context.GetElement().DisplayName
         trap { $overrideContextInstance = ""; continue } $overrideContextInstance = (Get-SCOMMonitoringObject -Id $override.ContextInstance).DisplayName
             
        if ($override.Monitor -ne $null){
             $overrideRuleMonitor = $override.Monitor.GetElement().DisplayName
         } elseif ($override.Discovery -ne $null){
             $overrideRuleMonitor = $override.Discovery.GetElement().DisplayName
         } else {
             $overrideRuleMonitor = $override.Rule.GetElement().DisplayName
         }
         
        #fills the current object with those properties
         $obj = $obj | add-member -membertype NoteProperty -name overrideName -value $overrideName -passthru
         $obj = $obj | add-member -membertype NoteProperty -name overrideProperty -value $overrideProperty -passthru
         $obj = $obj | add-member -membertype NoteProperty -name overrideValue -value $overrideValue -passthru
         $obj = $obj | add-member -membertype NoteProperty -name overrideContext -value $overrideContext -passthru
         $obj = $obj | add-member -membertype NoteProperty -name overrideContextInstance -value $overrideContextInstance -passthru
         $obj = $obj | add-member -membertype NoteProperty -name overrideRuleMonitor -value $overrideRuleMonitor -passthru
 

        #adds this current override to the array
         $MPRows = $MPRows + $obj
     }
 
    #exports to CSV
     $filename = $location + $mp.name + ".csv"
     $MPRows | Export-Csv $filename
 }
 
