#Requires Az PowerShell module, install with Install-Module Az
## https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-6.2.1
## https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-6.2.1

# If you have an existing AAD app client secret which will be expiring soon you can extend it's lifetime but adding a new secret with same value and later expiration date.

# Get service principal
$sp = Get-AzADServicePrincipal -DisplayName "MyTestApp"

# View current password Ids and expirations
Get-AzADSpCredential -ObjectId $sp.Id

# Choose expiration date
$start = get-date
$end = $start.AddYears(150)

#Set same password as current password so no end-app changes are needed. Note you would have to know your existing secret value.
$SecureStringPassword = ConvertTo-SecureString -String "c0[Ndh_@G/j8tB4aqbq66R]P*0MVwB.b" -AsPlainText -Force
New-AzADAppCredential -ApplicationId $sp.ApplicationId -StartDate $start -EndDate $end -Password $SecureStringPassword

# Verify new credential expiration
Get-AzADAppCredential -ApplicationId $sp.ApplicationId


# Remove old keyIds if no longer wanted, but can still auth with any non-expired credentials
Remove-AzADAppCredential -ApplicationId $sp.ApplicationId -KeyId "0272bba3-4894-4a93-895d-5be53be081b9"

# Note the app reg. portal may take ~10-15 minutes to reflect the same keyIds that PowerShell does