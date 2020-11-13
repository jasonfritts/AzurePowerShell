Install-Module AzureADPreview

Connect-AzureAD

# Create custom role with additional permissions MSI needs for SP creation
$allowedResourceAction = @()
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/createAsOwner")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/appRoleAssignedTo/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/audience/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/basic/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/create")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/credentials/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/delete")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/disable")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/enable")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/getPasswordSingleSignOnCredentials")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/managePasswordSingleSignOnCredentials")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/owners/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/permissions/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/policies/update")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronization/standard/read")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronizationCredentials/manage")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronizationJobs/manage")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronizationSchema/manage")
        $allowedResourceAction += @("microsoft.directory/servicePrincipals/tag/update")
        $rolePermission = @{'allowedResourceActions' = $allowedResourceAction}
        $rolePermissions = @()
        $rolePermissions += $rolePermission
        $resourceScopes = @()
        $resourceScopes += '/'
$newrole = New-AzureADMSRoleDefinition -RolePermissions $rolePermissions -IsEnabled $true -DisplayName 'Custom MSI Application Admin' -ResourceScope $resourceScopes

# Get managed identity princinpal to assign roles
$sp = Get-AzureADServicePrincipal -SearchString "VirtualMachineName"


# Assign custom role to MSI
New-AzureADMSRoleAssignment -RoleDefinitionId $newrole.Id -PrincipalId $sp.ObjectId -ResourceScope '/'

# Assign built in Application Administrator as well
$role = Get-AzureADMSRoleDefinition -Filter "displayName eq 'Application Administrator'"
New-AzureADMSRoleAssignment -RoleDefinitionId $role.Id -PrincipalId $sp.ObjectId -ResourceScope '/'