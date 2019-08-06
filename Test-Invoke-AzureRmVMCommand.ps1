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

$scriptfile = ".\script.sh"

Function WriteToScript
{
   Param ([string]$scriptline)

   Add-content $scriptfile -value $scriptline
}

WriteToScript "mkdir -p /home/vmadmin/testfolder1/shared/db;"
WriteToScript "mkdir -p /home/vmadmin/testfolder2/shared/db;"
WriteToScript "mkdir -p /home/vmadmin/testfolder3/shared/db;"

$files = Get-ChildItem
Write-Output $files
Invoke-AzureRmVMRunCommand -ResourceGroupName "vjomiLABrg" -Name LNX-VM1-VJOMI -CommandId "RunShellScript" -ScriptPath .\script.sh
