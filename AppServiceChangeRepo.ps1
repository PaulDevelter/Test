$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$webappname=(Get-AutomationVariable -Name 'AppServiceWebApp')
$rg=(Get-AutomationVariable -Name 'AppServiceRG')

$gitrepo=(Get-AutomationVariable -Name 'AppServiceRepo')
$gitBranch=(Get-AutomationVariable -Name 'AppServiceBranch')
$gittoken=(Get-AutomationVariable -Name 'SageNAPDevGitToken')

write-output "WebApp: $webappname, ResourceGroup: $rg, Git $gitrepo/$gitbranch"

Remove-AzureRmResource -ResourceGroupName $rg -ResourceType Microsoft.Web/sites/SourceControls -ResourceName $webappname/web -ApiVersion 2015-08-01 -Force

# SET GitHub
$PropertiesObject = @{
	token = $gittoken;
}
Set-AzureRmResource -PropertyObject $PropertiesObject -ResourceId /providers/Microsoft.Web/sourcecontrols/GitHub -ApiVersion 2015-08-01 -Force

# Configure GitHub deployment from your GitHub repo and deploy once.
$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "$gitbranch";
}
Set-AzureRmResource -PropertyObject $PropertiesObject -ResourceGroupName $rg -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname/web -ApiVersion 2015-08-01 -Force
write-output "Completed"