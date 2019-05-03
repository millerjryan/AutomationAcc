# Parameters 
    Param(
 
        [Parameter (Mandatory =$true)] 
        [string]$VMName,
        
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

#Check for each subscription to find VM   
    Get-AzureRmSubscription | ForEach-Object { 
        Write-Output "`n Looking into $($_.SubscriptionName) subscription..."   
   
        #Select subscription   
          
        Select-AzureRmSubscription -SubscriptionId $_.SubscriptionId
 
 
        # Get Running vm (azurevm) 
        $azurevm = Get-AzureRmVM -Status | where {$_.Name -eq $VMName}        
            if ($azurevm.PowerState -eq "VM Running") 
            { 
                Write-Output "Stopping $VMName in $ResourceGroup....."
                Stop-AzureRmVM -Name $azurevm.Name -ResourceGroupName $ResourceGroup
                $result = get-AzureRmVM -Status | where {$_.Name -eq $VMName}
                if($result.PowerState -ne "VM deallocated") 
                { 
                    Write-Output "- $($azurevm.Name) did not shutdown successfully"
                } 
                else 
                { 
                    Write-Output "+ $($azurevm.Name) shutdown successfully" 
                    Write-Output "+ $($azurevm.Name) is going to be started..."
                    Start-AzureRMVM -Name $azurevm.Name -ResourceGroupName $ResourceGroup
                    $startresults = Get-AzureRmVM -Status | where {$_.Name -eq $VMName}
                    if($startresults.PowerState -ne "VM Running")
                    {
                        Write-Output "+ $($azurevm.Name) did not start successfully"
                    }
                    else
                    {
                        Write-Output "+ $($azurevm.Name) started successfully"
                    }
                } 
            } 
            else 
            { 
                    Write-Output "$($azurevm.Name) is already stopped."
                    Start-AzureRMVM -Name $azurevm.Name -ResourceGroupName $ResourceGroup
                    $startresults2 = Get-AzureRmVM -Status | where {$_.Name -eq $VMName}
                    if($startresults2.PowerState -ne "VM Running")
                    {
                        Write-Output "+ $($azurevm.Name) did not start successfully"
                    }
                    else
                    {
                        Write-Output "+ $($azurevm.Name) started successfully"
                    } 
                 
            }  
        } 
  