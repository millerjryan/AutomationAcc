################
# Start of Variables (Edit these)

$VaultName = "<KEYVAULT NAME>"

$from = "<email address>"
$to = "<email address>"
$subject = "<Subject of email>"
$body = "<Body of email in plaintext>"

$reportname1 = "Inventory.csv"
#$reportname2 = "Public-IPs.csv"


$subscriptions = @(
	'TZF-EXT-MT-PERF-001',
	'TZF-INT-DEV-MGMT',
	'TZF-INT-DEV-MULTI-001',
    'TZF-PRD-MT-PROD-001',
    'TZF-PRD-MGMT',
    'TZF-INT-DEV-MEDAI-001',
    'TZF-EXT-MT-SIT-001',
    'TZF-EXT-MT-INTEG-001',
    'TZF-EXT-MT-LIFES-001',
    'TZF-INT-DEV-001',
    'TZF-INT-DEV-MULTI-002',
    'TZF-DEV-FACETS',
    'TZF-DEMO-FACETS',
    'TZF-UTILITY',
    'TZF-DEMO-MULTI-003',
    'TZF-PRD-MT-PREP-001',
    'TZF-EXT-MT-PAT-001',
    'TZF-DEMO-MULTI-002',
    'TZF-EXT-MT-SID-001',
    'TZF-DEMO-MULTI-001',
    'TZF-EXT-MT-DEMO-001'
)
#

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

<#
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
#>

################
# VM REPORT


$I = 0
$vmOutput = @()
foreach ($subscription in $subscriptions){
    $I++
    $J = 0
    $vmcount = 0
    Write-Progress -Activity "Scanning Subscriptions" -Status "Scanning: $subscription" -PercentComplete ($I/$subscriptions.Count*100) -Id 1
    $s = Get-AzSubscription -SubscriptionName $subscription
    Set-AzContext -SubscriptionId $s.Id
    $VMs = Get-AzVM    
    ForEach ($vm in $VMs) {$vmcount++}     
    ForEach ($vm in $VMs) {
    $J++
    Write-Progress -Activity "Scanning VMs" -Status "Scanning VMs" -PercentComplete ($J/$vmcount*100) -id 2
        $tmpObj = New-Object -TypeName PSObject 
        $tmpObj | Add-Member -MemberType Noteproperty -Name "VM Name" -Value $vm.Name 
        $tmpObj | Add-Member -MemberType Noteproperty -Name "OS type" -Value $vm.StorageProfile.OsDisk.OsType 
        $vmNICs = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName         
        ForEach ($nic in $vmNICs) {
            if ($nic.id -eq $vm.NetworkProfile.NetworkInterfaces[0].id) {
                $vmNIC = $nic
            }
        }
        $tmpObj | Add-Member -MemberType NoteProperty -Name "Private IP" -Value $vmNIC.IpConfigurations[0].PrivateIpAddress
        $VMDetail = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
        foreach ($VMStatus in $VMDetail.Statuses)
        { 
            if($VMStatus.Code -like "*PowerState*")
            {
                $VMStatusDetail = $VMStatus.DisplayStatus
            }
        }
        $tmpObj | Add-Member -MemberType NoteProperty -Name "Status" -Value $VMStatusDetail
        $tmpObj | Add-Member -MemberType NoteProperty -Name "Subscription" -Value $subscription
        $vmOutput += $tmpObj
         
    }
   
}
    #$vmOutput | Format-Table
    $vmOutput | Export-Csv -Path .\$reportname1
# End of VM REPORT
#################

<#
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
#>

#################
# SendMail

$attachments = @(
	".\$reportname1"
 #".\$reportname2"

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
