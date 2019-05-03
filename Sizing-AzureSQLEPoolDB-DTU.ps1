# Parameters 
    Param( 
        [Parameter (Mandatory= $true)] 
        [string]$ElasticPoolName, 
 
        [Parameter (Mandatory =$true)] 
        [string]$ResourceGroupName,
        
        [Parameter (Mandatory =$true)] 
        [string]$ServerName,

        [Parameter (Mandatory =$true)] 
        [int32]$DTU,
         
        [Parameter (Mandatory =$true)] 
        [int32]$DatabaseDTUMin,     

        [Parameter (Mandatory =$true)] 
        [int32]$DatabaseDTUMax,        
        
        [Parameter (Mandatory =$true)] 
        [string]$Edition

       ) 


################
# Auth with Azure

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
# End of Auth
################

# Get EPOOL first

$epooldb = Get-AzureRmSqlElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ElasticPoolName $ElasticPoolName

#debug finding resource
Write-Output "Printing the Epool DB data:::"
Write-Output "Before Change:"
Write-Output $epooldb
# Change EPOOL 
Write-Output "After Change:"
Set-AzureRmSqlElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ElasticPoolName $ElasticPoolName -Dtu $DTU -DatabaseDtuMax $DatabaseDTUMax -DatabaseDtuMin $DatabaseDTUMin