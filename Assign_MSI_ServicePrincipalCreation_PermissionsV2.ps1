﻿Install-Module AzureADPreview

Connect-AzureAD

# Create custom role with  permissions MSI needs for SP creation, a copy of built-in Application Administrator + additional permisisons for MSI princpals to create service principals
$allowedResourceAction = @()
$allowedResourceAction += @("microsoft.directory/applications/create")
$allowedResourceAction += @("microsoft.directory/applications/delete")
$allowedResourceAction += @("microsoft.directory/applications/applicationProxy/read")
$allowedResourceAction += @("microsoft.directory/applications/applicationProxy/update")
$allowedResourceAction += @("microsoft.directory/applications/applicationProxyAuthentication/update")
$allowedResourceAction += @("microsoft.directory/applications/applicationProxySslCertificate/update")
$allowedResourceAction += @("microsoft.directory/applications/applicationProxyUrlSettings/update")
$allowedResourceAction += @("microsoft.directory/applications/appRoles/update")
$allowedResourceAction += @("microsoft.directory/applications/audience/update")
$allowedResourceAction += @("microsoft.directory/applications/authentication/update")
$allowedResourceAction += @("microsoft.directory/applications/basic/update")
$allowedResourceAction += @("microsoft.directory/applications/credentials/update")
$allowedResourceAction += @("microsoft.directory/applications/owners/update")
$allowedResourceAction += @("microsoft.directory/applications/permissions/update")
$allowedResourceAction += @("microsoft.directory/applications/synchronization/standard/read")
$allowedResourceAction += @("microsoft.directory/applicationTemplates/instantiate")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/create")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/delete")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/standard/read")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/owners/read")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/policyAppliedTo/read")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/basic/update")
$allowedResourceAction += @("microsoft.directory/applicationPolicies/owners/update")
$allowedResourceAction += @("microsoft.directory/connectors/create")
$allowedResourceAction += @("microsoft.directory/connectors/allProperties/read")
$allowedResourceAction += @("microsoft.directory/connectorGroups/create")
$allowedResourceAction += @("microsoft.directory/connectorGroups/delete")
$allowedResourceAction += @("microsoft.directory/connectorGroups/allProperties/read")
$allowedResourceAction += @("microsoft.directory/connectorGroups/allProperties/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/create")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/delete")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/disable")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/enable")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/getPasswordSingleSignOnCredentials")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronizationCredentials/manage")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronizationJobs/manage")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronizationSchema/manage")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/synchronization/standard/read")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/managePasswordSingleSignOnCredentials")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/managePermissionGrantsForAll.microsoft-application-admin")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/appRoleAssignedTo/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/audience/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/authentication/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/basic/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/credentials/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/owners/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/permissions/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/policies/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/tag/update")
$allowedResourceAction += @("microsoft.directory/servicePrincipals/createAsOwner")
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
