$ClientID       = "b0eb5148-fa60-4b20-a4e9-a1d0bf2bd284"       # Insert your application's Client ID, a Globally Unique ID (registered by Global Admin)
$ClientSecret   = "k07eddfb-6561-4a13-9933-3f86ca352cf4"   # Insert your application's Client Key/Secret string
$loginURL       = "https://login.microsoftonline.com"     # AAD Instance; for example https://login.microsoftonline.com
$tenantdomain = "jasonfritts.onmicrosoft.com"  # AAD tenant ID
$vaultUri = "https://kvfritts2.vault.azure.net/secrets/Secret1/0193486d28034d35bf8334842d3efe0f?api-version=2016-10-01"   # Key Vault resource URI, include version

# Create HTTP header, get an OAuth2 access token based on client id, secret and tenant domain, change resource URL to match env. endpoint
$body       = @{grant_type="client_credentials";client_id=$ClientID;client_secret=$ClientSecret;resource="https://vault.azure.net"}
$oauth2     = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body



#Change Keyvault URL to match your vault
$KeyVaultToken = $oauth2.access_token
$result = (Invoke-WebRequest -Uri $vaulturi -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).content
$result = $result | ConvertFrom-Json
$result.value