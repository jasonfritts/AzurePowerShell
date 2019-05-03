$ClientID       = "0c5e5210-a4a8-4b59-9377-2dc739711496"       # Insert your application's Client ID, a Globally Unique ID (registered by Global Admin)
$ClientSecret   = "MDHVLwO8bE/XnNXXxoXcGz5pfsN4qauAGQab75Tr6FQ="   # Insert your application's Client Key/Secret string
$loginURL       = "https://login.microsoftonline.com"     # AAD Instance; for example https://login.microsoftonline.com
$tenantdomain = "91ceb514-5ead-468c-a6ae-048e103d57f0"
$keyvaultURI = "https://frittssanvault.vault.azure.net/secrets/secret/2de37f8ea5534eae8095fe2e74fa0df5?api-version=2016-10-01"

# Create HTTP header, get an OAuth2 access token based on client id, secret and tenant domain, change resource URL to match env. endpoint
$body       = @{grant_type="client_credentials";client_id=$ClientID;client_secret=$ClientSecret;resource="https://vault.azure.net"}
$oauth2     = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body



#Change Keyvault URL to match your vault
$KeyVaultToken = $oauth2.access_token
$result = (Invoke-WebRequest -Uri $keyvaultURI -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).content
$result = $result | ConvertFrom-Json
$result.value
