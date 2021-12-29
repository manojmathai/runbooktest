#Parameters needed by the script.
Param(     
	[Parameter(Mandatory=$True)]
    [string] $AutomationAccountName,
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName
)

Function ImportRunBook($automationAccountName, $runbookName, $scriptPath, $resourceGroupName) {
	Import-AzAutomationRunbook -Name $runbookName -Path $scriptPath -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Type PowerShellWorkflow -Force
	Write-Host "Completed importing $runbookName ."
}

$runbookName = "StopAnalysisService"
$scriptPath = "Runbook/StopAnalysisService.ps1"
ImportRunBook $AutomationAccountName $runbookName $scriptPath $ResourceGroupName
