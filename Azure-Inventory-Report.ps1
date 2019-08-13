<#PSScriptInfo

.VERSION 1.1

.GUID 43aad25b-71a6-4e88-a836-847a5f971460

.AUTHOR v-jomi

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI
https://raw.githubusercontent.com/millerjryan/AutomationAcc/master/Azure-Inventory-Report.ps1

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

#Requires -Module Az.Account
#Requires -Module Az.Compute
#Requires -Module Az.KeyVault
#Requires -Module Az.Network
#Requires -Module Az.Profile

<# 

.DESCRIPTION 
 Script that collects an Inventory of Azure Resources and emails a csv report.  Please fill in the missing fields in the Variables section. 

#> 
################
# Start of Variables (Edit these)

$VaultName = "<Name of KeyVault>"

$from = "Put in an email (XXXXX@XXXX.com)"
$to = "Put in an email (XXXXX@XXXX.com)"
$subject = "<Subject of email>"
$body = "<Body of email in plaintext>"

$reportname1 = "Inventory.csv"
$reportname2 = "Public-IPs.csv"

# End of Variables
################

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
$report1 | export-csv .\$reportname1 -delimiter ";" -force -notypeinformation
# End of VM REPORT
#################

#################
# Public IP Report

$report2 = @()
$pubIPs = Get-AzPublicIpAddress #| ?{ $_.IpAddress -NE "Not Assigned"}
$pubIPs

foreach($ip in $pubIPs)
{
$info = "" | Select Name, ResourceGroupName, IpAddress
$info.Name = $ip.Name
$info.ResourceGroupName = $ip.ResourceGroupName
$info.IpAddress = $ip.IpAddress
$report2+=$info
}

$report2 | export-csv .\$reportname2 -delimiter ";" -force -notypeinformation
# End of Public IP REPORT
#################

#################
# SendMail

$attachments = @(
	".\$reportname1"
        ".\$reportname2"

)

$securePassword = ConvertTo-SecureString $password -AsPlaintext -Force
$mailArgs = @{
	From =			$from  
	To =			$to  
	Subject =		$subject
	Body =			$body
	Attachments =	$attachments
	SmtpServer =	"smtp.sendgrid.net"
	Port =			587
	UseSSL =		$true
	Credential =	New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securePassword
}
Send-MailMessage @mailArgs

# End of SendMail
#################
