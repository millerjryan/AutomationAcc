
<#PSScriptInfo

.VERSION 1.0

.GUID ca155326-daef-4563-9c58-dcca674d02b2

.AUTHOR Joshua Miller

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Restarts Azure App Services 

#> 

Param()


# Parameters 
    Param(
 
        [Parameter (Mandatory =$true)] 
        [string]$WebAppName,
        
        [Parameter (Mandatory =$true)] 
        [string]$ResourceGroup
         
       ) 

#Auth
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

#Check for each subscription to find WebApp   
    Get-AzureRmSubscription | ForEach-Object { 
        Write-Output "`n Looking into $($_.SubscriptionName) subscription..."   
   
        #Select subscription   
          
        Select-AzureRmSubscription -SubscriptionId $_.SubscriptionId
 
 
        # Get Running WebApps (Websites) 
        $websites = Get-AzureRmWebApp | where {$_.Name -eq $WebAppName}        
            if ($websites.State -eq "Running") 
            { 
                Write-Output "Stopping $WebAppName in $ResourceGroup....."
                $result = Stop-AzureRmWebApp -Name $websites.Name -ResourceGroupName $ResourceGroup
                if($result.State -ne "Stopped") 
                { 
                    Write-Output "- $($websites.Name) did not shutdown successfully"
                } 
                else 
                { 
                    Write-Output "+ $($websites.Name) shutdown successfully" 
                    Write-Output "+ $($websites.Name) is going to be started..."
                    $startresults = Start-AzureRMWebApp -Name $websites.Name -ResourceGroupName $ResourceGroup
                    if($startresults.State -ne "Running")
                    {
                        Write-Output "+ $($websites.Name) did not start successfully"
                    }
                    else
                    {
                        Write-Output "+ $($websites.Name) started successfully"
                    }
                } 
            } 
            else 
            { 
                    Write-Output "$($websites.Name) is already stopped."
                    $startresults2 = Start-AzureRMWebApp -Name $websites.Name -ResourceGroupName $ResourceGroup
                    if($startresults2.State -ne "Running")
                    {
                        Write-Output "+ $($websites.Name) did not start successfully"
                    }
                    else
                    {
                        Write-Output "+ $($websites.Name) started successfully"
                    } 
                 
            }  
        } 
  
