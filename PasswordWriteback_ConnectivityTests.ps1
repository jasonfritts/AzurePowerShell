# Verify SSPR writeback config is enabled \ started and onboarding is not required
$aadconnector = Get-ADSyncConnector | ? {$_.Name -match " - AAD"}
Get-ADSyncAADPasswordResetConfiguration -Connector $aadconnector.Name


# From event logs check the most recent service bus heartbeat (should be every ~ 5 minutes) and copy the Namespace and Endpoint
$date = (Get-Date).AddHours(-1)
$output = Get-WinEvent -FilterHashTable @{ LogName = "Application"; ProviderName = "PasswordResetService"; Id = 31019; StartTime = $date } | Select -First 2 TimeCreated, Message | fl *

# Based on results customize below variable examples with the two namespace\endpoints in use
$Namespace1 = "ssprdedicatedsbprodncu"
$Endpoint1 = "91ceb514-5ead-468c-a6ae-048e103d57f0_2e53b84b-d06a-4e44-9f79-cd3d7f7814f7"

$Namespace2 = "ssprdedicatedsbprodscu"
$Endpoint2 = "91ceb514-5ead-468c-a6ae-048e103d57f0_7bc234a4-5dd9-46b3-a136-1876080cb275"


# Export PasswordReset + ADSync Event Logs for last 48 hours and upload to support case DTM for review
wevtutil.exe epl Application C:\Temp\PasswordResetServiceLogs.evtx /ow:True /q:"*[System[Provider[@Name='PasswordResetService'] and TimeCreated[timediff(@SystemTime) <= 172800000]]]"
wevtutil.exe epl Application C:\Temp\AdSyncLogs.evtx /ow:True /q:"*[System[Provider[@Name='ADSync'] and TimeCreated[timediff(@SystemTime) <= 172800000]]]"

# Verify DNS Resolution
$IP1 = (Resolve-DnsName "$Namespace1.servicebus.windows.net").IP4Address
$IP1
$IP2 = (Resolve-DnsName "$Namespace2.servicebus.windows.net").IP4Address
$IP2

# Check for the persistent outbound connection established to service bus relay
$process = get-process -Name miiserver
Get-NetTCPConnection -State Established -OwningProcess $process.Id -RemotePort 443 -RemoteAddress $IP1
Get-NetTCPConnection -State Established -OwningProcess $process.Id -RemotePort 443 -RemoteAddress $IP2


# Verify browser can connect to full endpoint and the expected response "MissingToken: The request contains no authorization header" is returned, if there is any other response could be outbound connectivity issue
Start-Process msedge.exe -ArgumentList "https://$Namespace1.servicebus.windows.net/$Endpoint1 -inprivate"
Start-Process msedge.exe -ArgumentList "https://$Namespace2.servicebus.windows.net/$Endpoint2 -inprivate"

# Response should be "401 Unauthorized" if it is anything else there could be outbound connectivity issue
Invoke-RestMethod -Method Get -Uri "https://$Namespace1.servicebus.windows.net/$Endpoint1"

# Response should be "401 Unauthorized" if it is anything else there could be outbound connectivity issue
Invoke-RestMethod -Method Get -Uri "https://$Namespace2.servicebus.windows.net/$Endpoint2"




# Run SSL\TLS tests from https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-tls-enforcement#powershell-script-to-check-tls-12


Function Get-ADSyncToolsTls12RegValue
{
    [CmdletBinding()]
    Param
    (
        # Registry Path
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]
        $RegPath,

        # Registry Name
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string]
        $RegName
    )
    $regItem = Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction Ignore
    $output = "" | select Path,Name,Value
    $output.Path = $RegPath
    $output.Name = $RegName

    If ($regItem -eq $null)
    {
        $output.Value = "Not Found"
    }
    Else
    {
        $output.Value = $regItem.$RegName
    }
    $output
}

$regSettings = @()
$regKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SystemDefaultTlsVersions'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SchUseStrongCrypto'

$regKey = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SystemDefaultTlsVersions'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SchUseStrongCrypto'

$regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'Enabled'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'DisabledByDefault'

$regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'Enabled'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'DisabledByDefault'

$regSettings














### Testing outbound block behavior

# Enable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Resolve the IP address of service bus endpoints
$servicebusIP1 = [System.Net.Dns]::GetHostAddresses("$Namespace1.servicebus.windows.net").IPAddressToString
$servicebusIP2 = [System.Net.Dns]::GetHostAddresses("$Namespace2.servicebus.windows.net").IPAddressToString


# Create an outbound rule to block traffic to www.google.com
New-NetFirewallRule -DisplayName "Block Service Bus IP1" -Direction Outbound -Action Block -RemoteAddress $servicebusIP1
New-NetFirewallRule -DisplayName "Block Service Bus IP2" -Direction Outbound -Action Block -RemoteAddress $servicebusIP2


#Reset firewall
Remove-NetFirewallRule -DisplayName "Block Service Bus IP1"
Remove-NetFirewallRule -DisplayName "Block Service Bus IP2"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False