Param(

[Parameter(Mandatory = $false)]
[string] $emailSmtpServer = "smtp.sendgrid.net",

[Parameter(Mandatory = $false)]
[string] $emailSmtpServerPort = 587,

[Parameter(Mandatory = $true)]
[string] $sendGridUserName,

[Parameter(Mandatory = $true)]
[string] $sendGridPassword,

[Parameter(Mandatory = $true)]
[string] $emailFrom,

[Parameter(Mandatory = $true)]
[string] $emailTo,

[Parameter(Mandatory = $false)]
[string] $minimumCertAgeDays = 30

)

# This script has been created by Bram Stoop
# Feel free to visit my website https://bramstoop.com/ and leave me comments/give me feedback on this runbook
# You can also follow me on twitter https://twitter.com/bramstoopcom

# This runbook will check all certificates, within your subscription, on expiration date.
# By default it uses sendgrid for mail notifications.

# Make sure you have the AzureRM.websites module installed withing Azure Automation
# Keep in mind that the Sendgrid username has this format azure_somekindofnumber@azure.com - this can be found in the azure portal

$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
} catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$currentSubscription = (Get-AzureRmContext).Subscription
$resourceGroups = Get-AzureRmResourceGroup
$securePassword=ConvertTo-SecureString $sendGridPassword -asplaintext -force 
$credential = New-Object System.Management.Automation.PsCredential($sendGridUserName,$securePassword)
$emailSmtpUser  = $credential.UserName
$emailSmtpPass=$credential.GetNetworkCredential().Password

if ($resourceGroups) 
{
    foreach ($ResourceGroup in $resourceGroups)
     {
        $ResourceGroupName = "$($ResourceGroup.ResourceGroupName)"
        $allCertificates = Get-AzureRmWebAppCertificate -ResourceGroupName $ResourceGroupName

           foreach ($certificate in $allCertificates)
            {

                [datetime]$expiration = $($certificate.ExpirationDate)
                [int]$certExpiresIn = ($expiration - $(get-date)).Days

                if ($certExpiresIn -gt $minimumCertAgeDays)
                    {
                        Write-Output "$($certificate.FriendlyName) expiry date is $($certificate.ExpirationDate)" -f Green
                        Write-Output "Certificate for $($certificate.FriendlyName) expires in $certExpiresIn days [on $expiration]" -f Green
                    }
                else
                    {

Write-Output "WARNING: Certificate with friendly name: $($certificate.FriendlyName) expires in $certExpiresIn days [on $expiration] `
This certificate can be found in resourcegroup: $($ResourceGroup.ResourceGroupName) `
Existing in subscription with name: $($currentSubscription.Name)"

$subject =  "WARNING: Certificate with friendly name: $($certificate.FriendlyName) expires in $certExpiresIn days"
$body    = "<hr><font color=#FF0000><b>WARNING:</b><br>Certificate with friendly name: $($certificate.FriendlyName)<br> `
Expires in: $certExpiresIn days on $expiration</font><br> `
<hr>This certificate can be found in resourcegroup: $($ResourceGroup.ResourceGroupName)<br> `
Existing in subscription:<br>
<li> Name: $($currentSubscription.Name)<br></li>
<li> Subscription Id: $($currentSubscription.Id)<br></li>
<li> Tenant Id: $($currentSubscription.TenantId)<br></li><hr>"
#If you want to extend your message you can use the expression underneath
#$body    += "<font face='Courier' color=#446699>Your company name website <a href='https://www.mycompanyname.com'>mycompanyname.com</a></font>"   

$emailMessage = New-Object System.Net.Mail.MailMessage( $emailFrom , $emailTo, $subject, $body )
$emailMessage.IsBodyHTML=$true

$SMTPClient = New-Object System.Net.Mail.SmtpClient( $emailSmtpServer , $emailSmtpServerPort )
$SMTPClient.EnableSsl = $True
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );
$SMTPClient.Send( $emailMessage )

                    }

            }
     }
}

else
{
    Write-Output "There are no resourcegroups within this subscription"
}