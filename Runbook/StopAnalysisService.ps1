Param(     
	[Parameter(Mandatory=$True)]    [string] $AutomationAccountName,
	[Parameter(Mandatory=$True)]    [string] $ResourceGroupName,
	[Parameter(Mandatory=$True)]    [string] $AnalysisServerName
)

try
{

    Write-Output "Connecting to Azure"
    $ConnectionName = 'AzureRunAsConnection'
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName      
	
	Connect-AzAccount -Identity
	$AzureContext = (Connect-AzAccount -Identity).context
	$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

    Write-Output "Connected "
    Write-Output "Connecting to analysis service to get status "
    

   $asSrv=Get-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
   If ($asSrv.State -eq "Paused")
   {
       Write-Output "Server is not running "
   }
   else
   {
       Write-Output "Server is  running, ..  stopping the service"
       #Suspend-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $AnalysisServerName
   }
    
}
catch 
{
    Write-output -Message $_.Exception.Message
}