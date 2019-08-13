################
# Auth with Azure

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzAccount `
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

################
# Get SendGrid API key
$VaultName = "vjomiLABkv"

$username = "apikey"
$password = (Get-AzKeyVaultSecret -VaultName $VaultName -Name "SendGridAPIKey").SecretValueText

# End of SendGrid API
#################

################
# VM REPORT
$report1 = @()
$vms = get-azvm
$nics = get-aznetworkinterface | ?{ $_.VirtualMachine -NE $null}

foreach($nic in $nics)
{
$info = "" | Select VmName, ResourceGroupName, IpAddress, OSType
$vm = $vms | ? -Property Id -eq $nic.VirtualMachine.id
$info.VMName = $vm.Name
$info.ResourceGroupName = $vm.ResourceGroupName
$info.IpAddress = $nic.IpConfigurations.PrivateIpAddress
$info.OStype = $vm.StorageProfile.osDisk.osType
$report1+=$info
}
$report1 | export-csv .\Tzf-DEMO-FACET.csv -delimiter ";" -force -notypeinformation
# End of VM REPORT
#################

#################
# Public IP Report

$report2 = @()
$pubIPs = Get-AzPublicIpAddress | ?{ $_.VirtualMachine -NE $null}
$pubIPs

foreach($ip in $pubIPs)
{
$info = "" | Select Name, ResourceGroupName, IpAddress
$info.Name = $ip.Name
$info.ResourceGroupName = $ip.ResourceGroupName
$info.IpAddress = $ip.IpAddress
$report2+=$info
}
$report2
$report2 | export-csv .\Txf-Public-ip.csv -delimiter ";" -force -notypeinformation
# End of Public IP REPORT
#################

#################
# SendMail

$attachments = @(
	".\Tzf-DEMO-FACET.csv"
    ".\Txf-Public-ip.csv"

)

$securePassword = ConvertTo-SecureString $password -AsPlaintext -Force
$mailArgs = @{
	From =			"V-JOMI@MICROSOFT.com"  # Put in an email (XXXXX@XXXX.com)
	To =			"V-JOMI@MICROSOFT.com"  # (XXXXX@XXXX.com)
	Subject =		"Azure Inventory Summary Report"
	Body =			"Azure Inventory. Please review the attached file. Thank You"
	Attachments =	$attachments
	SmtpServer =	"smtp.sendgrid.net"
	Port =			587
	UseSSL =		$true
	Credential =	New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword
}
Send-MailMessage @mailArgs

# End of SendMail
#################
