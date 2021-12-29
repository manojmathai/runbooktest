#Parameters needed by the script.
Param(     
	[Parameter(Mandatory=$True)]    [string] $AutomationAccountName,
	[Parameter(Mandatory=$True)]    [string] $ResourceGroupName,
    [Parameter(Mandatory=$True)]    [string] $WorkspaceName,
    [Parameter(Mandatory=$True)]    [string] $SynapseSqlPoolName,
    [Parameter(Mandatory=$True)]    [string] $SQL_Server_Name,
	[Parameter(Mandatory=$True)]    [string] $keyvault
)

Import-Module Az.Accounts
Import-Module Az.Sql
Import-Module Az.Synapse

# Connect via Managed Identity
Connect-AzAccount -Identity
$AzureContext = (Connect-AzAccount -Identity).context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext


# Get credentials from automation credentials 
try
{
    Write-Output "Get sql credentials from Key-Vault"
    $secretuser = Get-AzKeyVaultSecret -VaultName $keyvault -Name 'SQLAdminUser' -AsPlainText
    Write-Output "Sec USr"
	$secretpass = Get-AzKeyVaultSecret -VaultName $keyvault -Name 'SQLAdminPass' -AsPlainText
	$secpass = ConvertTo-SecureString -String "$secretpass" -AsPlainText -Force
	$SQLServerCred = New-Object System.Management.Automation.PSCredential ($secretuser, $secpass)
	$CredObj = New-Object System.Management.Automation.PSCredential ($secretuser, $secpass)
	Write-Output "Check if there are active queries " 
	$Query = "SELECT * FROM sys.dm_exec_requests Where status='Running'"
	$dsInstanceList=invoke-sqlcmd2 -ServerInstance "$SQL_Server_Name" -Database "$SynapseSqlPoolName" -Credential $SQLServerCred -Query "$Query" -As 'DataTable'
	$querycounter =0
	foreach($Instance in $dsInstanceList.rows)
	{
		$querycounter = $querycounter + 1
	}
	Write-Output "Query Count " $querycounter
	if ($querycounter -eq 1 )
	{
		Write-Output "No active queries ,connecting to sqlpool to stop "
		Write-Output "Stopping ...   "
		Suspend-AzSynapseSqlPool -WorkspaceName $WorkspaceName -Name $SynapseSqlPoolName
		Write-Output "stopped  the server  "
	}
	else 
	{
		Write-Output "There are active queries"
		Write-Output $querycounter
		Write-Output "Quit without stopping "
	}
}
catch 
{
	Write-output $_.Exception.Message
}


