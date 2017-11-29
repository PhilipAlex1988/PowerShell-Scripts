#============================================================================
# AUTHOR:  Philip Alex 
# DATE:    07/06/2017
# Name:    Unix Maintenance Mode list servers.ps1
# Version: 1.0
# COMMENT: Puts a list of Unix Servers in Maintenance Mode in SCOM 2012
#============================================================================

#======================================================================================================
# Script Usage
# & '.\Unix Maintenance Mode list servers.ps1'-TimeMin 30 -Reason PlannedOther -Comment "INC000005423"
#======================================================================================================

#===============================================================================================================================================
# Reason Parameters that can be used
# PlannedOther, UnplannedOther, PlannedHardwareMaintenance, UnplannedHardwareMaintenance, PlannedHardwareInstallation,
# UnplannedHardwareInstallation, PlannedOperatingSystemReconfiguration, UnplannedOperatingSystemReconfiguration, PlannedApplicationMaintenance,
# UnplannedApplicationMaintenance, ApplicationInstallation, ApplicationUnresponsive, ApplicationUnstable, SecurityIssue, System.NetworkDevice
#===============================================================================================================================================

param([int32]$TimeMin, [string]$Reason, [string]$Comment)
                 $api = new-object -comObject 'MOM.ScriptAPI'
                 Import-Module operationsmanager
                 New-SCOMManagementGroupConnection
                 $Servers = Get-Content "ServerList.txt"
                 $Time = (Get-Date).Addminutes($TimeMin)
                 Foreach ($Server in $Servers)
                 {
                                 #Get Computer instance
                                 $ComputerClass = Get-SCOMClass -Name Microsoft.Unix.Computer
                                 $ComputerClassInstance = Get-SCOMClassInstance  -Class $ComputerClass | Where {$_.DisplayName -eq $Server}
                                
                                 If ($ComputerClassInstance.InMaintenanceMode -eq $true)
                                 {
                                 #Write-Host $Server " is in maintenance mode"
                                 Write-Host $Server" already under Maintenance Mode or not accessible by SCOM, skipped from script execution" -foregroundcolor "red"
                                 $api.LogScriptEvent('Unix Maintenance Mode list servers.ps1', 201, 1, "$Server already found under MM, skipped from script execution")
                                 }
                                 Else
                                 {
                                 #Write-Host $Server " is NOT in maintenance mode, attempting to put in MM......."
                                 If ($ComputerClassInstance -ne $Null)
                                 {
                                                 $HealthServiceWatcherClass = Get-SCOMClass -name:Microsoft.SystemCenter.HealthServiceWatcher
                                                 #Get Health Service Watcher Class instance of the server
                                                 $HSWClass = Get-SCOMClass -Name Microsoft.SystemCenter.HealthServiceWatcher
                                                 $HSWClassIns = Get-SCOMClassInstance  -Class $HSWClass | Where {$_.DisplayName -eq $Server}
                                                 #Starting the maintenance mode
                                                 #Start-SCOMMaintenanceMode -Instance $HSWClassIns -EndTime $Time -Reason $Reason -Comment $Comment
                                                 Start-SCOMMaintenanceMode -Instance $ComputerClassInstance -EndTime $Time  -Reason $Reason -Comment $Comment
                                                 Write-Host "Health Service Watcher and Agent server "$Server " kept in maintenance mode for $TimeMin minutes"  -foregroundcolor "green"
                                                 $api.LogScriptEvent('Unix Maintenance Mode list servers.ps1', 200, 0, "$Server kept in maintenance mode for $TimeMin minutes")
                                 }
                                 Else
                                 {
                                                 Write-Host $Server" not found in Domain" -foregroundcolor "red"
                                                 $api.LogScriptEvent('Unix Maintenance Mode list servers.ps1', 202, 1, "$Server not found in domain")
                                 }
                                 }
                 }
