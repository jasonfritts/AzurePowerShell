###############################################
### Prepare your repro AAD Tenant             #
###############################################

# NOTE: Must have AzureADPreview module installed, install with cmd Install-Module AzureADPreview

# Connect to Repro tenant with global admin
Connect-AzureAD -TenantId "reprotenant.onmicrosoft.com"

# Invite your microsoft.com alias as a guest
$invite = New-AzureADMSInvitation -InvitedUserEmailAddress alias@microsoft.com -SendInvitationMessage $True -InviteRedirectUrl "http://myapps.onmicrosoft.com"

# Create needed service principals for AAD DS.  Don't change these IDs. If error is servicePrincipalNames already exists, ignore.
New-AzureAdServicePrincipal -AppId "2565bd9d-da50-47d4-8b85-4c97f669dc36"
New-AzureAdServicePrincipal -AppId "d87dcbc6-a371-462e-88e3-28ad15ec4e64"
New-AzureAdServicePrincipal -AppId "443155a6-77f3-45e3-882b-22b3a8d431fb"
New-AzureAdServicePrincipal -AppId "abba844e-bc0e-44b0-947a-dc74e5d09022"

# Create security group for Azure Lighthouse Contributors
$group = New-AzureADGroup -DisplayName "Azure Lighthouse Contributors" -SecurityEnabled $true -MailEnabled $false -MailNickName "azurelighthouse"

# Add your invited microsoft.com alias to Azure Lighthouse Contributors group
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $invite.InvitedUser.Id

# Add your invited microsoft.com alias to Global Administrator role
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole -Filter "DisplayName eq 'Global Administrator'").ObjectId -RefObjectId $invite.InvitedUser.Id

# Add all the AAD DS service principals to Azure Lighthouse Contributors group
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId (Get-AzureADServicePrincipal -Filter "appId eq '2565bd9d-da50-47d4-8b85-4c97f669dc36'").ObjectId
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId (Get-AzureADServicePrincipal -Filter "appId eq 'd87dcbc6-a371-462e-88e3-28ad15ec4e64'").ObjectId
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId (Get-AzureADServicePrincipal -Filter "appId eq '443155a6-77f3-45e3-882b-22b3a8d431fb'").ObjectId
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId (Get-AzureADServicePrincipal -Filter "appId eq 'abba844e-bc0e-44b0-947a-dc74e5d09022'").ObjectId


####################################################################################################
# Prepare your AIRS Subscription                                                                   #
####################################################################################################

# NOTE: You must have installed Azure Powershell module first, if not install with cmd Install-Module Az

#####################################################
# Modify below variables to match your enviornment  #
#####################################################

# set your AIRS subscription ID
$subscriptionID = "eb3b1001-b064-40c1-ae8c-399c102ab254"

# set your Repro AAD tenant ID
$tenantID = "91ceb514-5ead-468c-a6ae-048e103d57f0"

# set your Repro tenant object ID for group "Azure Lighthouse Contributors"
$groupid = "1d2a07d6-3022-45cd-8b23-261f813af818"

# Login with your @microsoft.com alias
Connect-AzAccount -Subscription $subscriptionID
Set-AzContext -Subscription $subscriptionID

# Register needed resource providers
Register-AzResourceProvider -ProviderNamespace "Microsoft.AAD"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Network"
Register-AzResourceProvider -ProviderNamespace "Microsoft.aadiam"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Authorization"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Automanage"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Automation"
Register-AzResourceProvider -ProviderNamespace "Microsoft.AzureActiveDirectory"
Register-AzResourceProvider -ProviderNamespace "Microsoft.DeploymentManager"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Marketplace"
Register-AzResourceProvider -ProviderNamespace "Microsoft.SaaS"
Register-AzResourceProvider -ProviderNamespace "Microsoft.Storage"
Register-AzResourceProvider -ProviderNamespace "Microsoft.ManagedServices"

# Deploy Azure Lighthouse Permissions, do not modify below
$def = New-AzManagedServicesDefinition -Name "Azure Lighthouse for AADDS" -ManagedByTenantId $tenantID -PrincipalId $groupid -RoleDefinitionId "b24988ac-6180-42a0-ab88-20f7382dd24c" -Description "Grant Azure Lighthouse contributor role on subscription"
New-AzManagedServicesAssignment -RegistrationDefinition $def


# Next login to portal.azure.com w/microsoft.com alias,  switch directories to your repro tenant, then set directory\subscription filter to ALL
# Now browse to All Services -> Azure AD Domain Services -> Deploy\Create to your AIRS Subscription
