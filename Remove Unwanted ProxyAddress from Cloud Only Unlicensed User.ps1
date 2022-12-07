# README
# This script will assist in removing an unwanted ProxyAddress from an AAD Cloud Only \ Unlicensed (no EXO) user
# For such a user, the proxyAddresses attribute is Read Only.  So the below workaround is only option to remove unwanted ProxyAddress from such a user
#
# NOTE: If the user is a synched user, updating ProxyAddresses can be done from on-prem AD and Synched to user
# NOTE: If the user is a EXO licensed user, updating ProxyAddresses can be done from the Exchange or M365 Admin Portal

# Install required modules
Install-Module AzureADPreview
Install-Module MSOnline

# Connect to AAD with Global Admin etc.
Connect-MsolService
Connect-AzureAD



# Step 1: Locate the user who currently holds the unwanted proxy address
$proxy = "unwanted@domain.com"
$user = Get-AzureADUser -Filter "proxyAddresses/any(p:startswith(p,'smtp:$proxy'))"

# Step 2. Temporarily soft-delete the user who holds the unwanted proxy address
Remove-AzureADUser -ObjectId $user.ObjectID

# Step 3. Create a dummy user for moving the unwanted proxy to
$dummy = New-MsolUser -UserPrincipalName "dummyproxy@mytenant.onmicrosoft.com" -DisplayName "dummy proxy"

# Step 4. Add the unwanted proxy address to the dummy user
Set-AzureADUserExtension -ExtensionName Mail -ExtensionValue $proxy -ObjectId $dummy.ObjectId

# Verify the proxy to remove is on the dummy user now
Get-AzureADUser -ObjectId $dummy.ObjectId | Select UserPrincipalName, ObjectID, Mail, proxyAddresses| ft

# Step 5. Restore soft-deleted original user and auto remove the unwanted proxy
Restore-MsolUser -ObjectId $user.ObjectId -AutoReconcileProxyConflicts

# Verify the proxy to remove no longer exists on original user after restoration
Get-AzureADUser -ObjectId $user.ObjectId| Select UserPrincipalName, ObjectID, Mail, proxyAddresses| ft

# Step 6. Once verified delete the dummy user and the unwanted proxy
Remove-AzureADUser -ObjectId $dummy.ObjectID

