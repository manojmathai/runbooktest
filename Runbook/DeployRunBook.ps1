#Parameters needed by the script.
Param(     
	[Parameter(Mandatory=$True)]
    [string] $AutomationAccountName,
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName,
	[Parameter(Mandatory=$True)]
    [string] $WorkspaceName,
	[Parameter(Mandatory=$True)]
    [string] $SynapseSqlPoolName,
	[Parameter(Mandatory=$True)]
    [string] $SQL_Server_Name,
  [Parameter (Mandatory=$True)]
    [string] $AnalysisServerName,
	[Parameter(Mandatory=$True)]
    [string] $keyvault
)

Function ImportRunBook($automationAccountName, $runbookName, $scriptPath, $resourceGroupName) {
	Import-AzAutomationRunbook -Name $runbookName -Path $scriptPath -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Type PowerShellWorkflow -Force
	Write-Host "Completed importing $runbookName ."
}

Function PublishRunBook($automationAccountName, $runbookName, $resourceGroupName) {
	Publish-AzAutomationRunbook -AutomationAccountName $automationAccountName -Name $runbookName -ResourceGroupName $resourceGroupName
	Write-Host "Completed publishing $runbookName ."
}

Function ScheduleRunBook($automationAccountName, $runbookName, $resourceGroupName, $scheduleName, $params) {
	try
	{
		$existingSchedule = Get-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name $scheduleName -ResourceGroupName $resourceGroupName -ErrorAction Stop
		Write-Host "Schedule $scheduleName already exists."
	}
	catch [Microsoft.Azure.Commands.Automation.Common.ResourceNotFoundException]
	{
		$startTime = (Get-Date).AddMinutes(7)
		New-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name $scheduleName -StartTime $startTime -ResourceGroupName $resourceGroupName -HourInterval 3
		Write-Host "Completed adding schedule $scheduleName ."
		Register-AzAutomationScheduledRunbook –AutomationAccountName $automationAccountName –Name $runbookName –ScheduleName $scheduleName –Parameters $params -ResourceGroupName $resourceGroupName
		Write-Host "Completed linking runbook $runbookName to schedule $scheduleName ."
	}		
}

Function ScheduleAnalysisServices($automationAccountName, $runbookName, $resourceGroupName, $AASscheduleName, $params) {
	try
	{
		$existingSchedule = Get-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name $AASscheduleName -ResourceGroupName $resourceGroupName -ErrorAction Stop
		Write-Host "Schedule $AASscheduleName already exists."
	}
	catch [Microsoft.Azure.Commands.Automation.Common.ResourceNotFoundException]
	{
		$startTime = (Get-Date).AddMinutes(7)
		New-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name $AASscheduleName -StartTime $startTime -ResourceGroupName $resourceGroupName -HourInterval 3
		Write-Host "Completed adding schedule $AASscheduleName ."
		Register-AzAutomationScheduledRunbook -AutomationAccountName $automationAccountName -Name $runbookName -ScheduleName $AASscheduleName -Parameters $params -ResourceGroupName $resourceGroupName
		Write-Host "Completed linking runbook $runbookName to schedule $AASscheduleName ."
	}
}

$deps1 = @("Az.Accounts", "Az.Synapse", "Az.SQL", "Invoke-SqlCmd2")

foreach($dep in $deps1){
    $module = Find-Module -Name $dep
    $link = $module.RepositorySourceLocation + "/package/" + $module.Name + "/" + $module.Version
    New-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $module.Name -ContentLinkUri $link -ResourceGroupName $ResourceGroupName
}


$runbookName = "StopSQLPool"
$scriptPath = "Runbook/StopSQLPool.ps1"
ImportRunBook $AutomationAccountName $runbookName $scriptPath $ResourceGroupName
PublishRunBook $AutomationAccountName $runbookName $ResourceGroupName 

$scheduleName = "StopSQLPoolSchedule"
$params = @{"AutomationAccountName"=$AutomationAccountName;"ResourceGroupName"=$ResourceGroupName;"WorkspaceName"=$WorkspaceName;"SynapseSqlPoolName"=$SynapseSqlPoolName;SQL_Server_Name=$SQL_Server_Name;keyvault=$keyvault}
ScheduleRunBook $AutomationAccountName $runbookName $ResourceGroupName $scheduleName $params

$runbookName = "StopAnalysisService"
$scriptPath = "Runbook/StopAnalysisService.ps1"
ImportRunBook $AutomationAccountName $runbookName $scriptPath $ResourceGroupName
PublishRunBook $AutomationAccountName $runbookName $ResourceGroupName

$AASscheduleName = "StopAASSchedule"
$params = @{"AutomationAccountName"=$AutomationAccountName;"ResourceGroupName"=$ResourceGroupName;"AnalysisServerName"=$AnalysisServerName}
ScheduleAnalysisServices $AutomationAccountName $runbookName $ResourceGroupName $AASscheduleName $params
