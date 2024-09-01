function Parse-JWTtoken {
 
    [cmdletbinding()]
    param([Parameter(Mandatory=$true)][string]$token)
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID tokens are fine, Refresh tokens will not work
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
 
    #Header
    $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | fl | Out-Default
 
    #Payload
    $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $tokenPayload
    #Convert to Byte array
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    #Convert to string array
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $tokenArray
    #Convert from JSON to PSObject
    $tokobj = $tokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}


#Populate these values to be your tenant values

    $tenantdomain = "contoso.b2clogin.com/contoso.onmicrosoft.com"
    $policyID = "B2C_1A_V1_SIGNUP_SIGNIN"
    $clientID = "abc1eec2-f0f5-46a4-bbb7-168477bc9d6e"    # must register as app registration in B2C tenant
    $redirect_uri = "https://oidcdebugger.com/debug"      # must register as redirect_uri on above app registration
    $code_challenge = "aBcrswFkRESsoPZP2Cs21M-Jl-F1OLdFGWgjEKdHEcI"  #must be a valid code_challenge\code_verifier for PKCE (for test use online generator like https://referbruv.com/utilities/pkce-generator-online/)
    $code_verifier = "eyIxIjoxNjgsIjIiOjEyNSwiMyI6NzAsIjQiOjEyMX0"

    # this must be a Oauth API you have registered in tenant
    $scope = "https://contoso.onmicrosoft.com/web-api1-msalJS-demo/task.read+offline_access"
    $username = "testing@gmail.com"


# Do not modify
    $baseURL = "https://$tenantdomain/oauth2/v2.0/authorize?p=$policyID&client_id=$clientID&redirect_uri=$redirect_uri&scope=$scope&response_type=code&prompt=login&code_challenge=$code_challenge&code_challenge_method=S256"

# Interactive Login with browser to provide authorization and obtain authorization code, use copy code button from browser to copy authZ code to clipboard
    Set-Clipboard -Value $username
    Start-Process msedge.exe -ArgumentList "$baseURL -inprivate"

# Exchange AuthZ code for a access token

    $response = $null #clear any previous session

    $grant_type = "authorization_code"
    $code = Get-Clipboard
    $redirect_uri = "https://oauth.pstmn.io/v1/callback"

    $baseURL = "https://$tenantdomain/$policyID/oauth2/v2.0/token?grant_type=$grant_type&code=$code&redirect_uri=$redirect_uri&client_id=$clientID&code_verifier=$code_verifier"
    $response = Invoke-RestMethod -Method Get -Uri $baseURL
    $response

    $parsed = Parse-JWTtoken $response.access_token
    $parsed

    $iat = (([System.DateTimeOffset]::FromUnixTimeSeconds($parsed.iat)).DateTime).ToString("s")
    $exp = (([System.DateTimeOffset]::FromUnixTimeSeconds($parsed.exp)).DateTime).ToString("s")

    Write-Host "Access token was issued at $iat and will expire on $exp" -ForegroundColor Cyan

   
    #Parse-JWTtoken $response.id_token

# Use refresh_token to obtain a new token \ re-run to continue getting tokens
    $grant_type = "refresh_token"
    $refresh_token = $response.refresh_token

    $baseURL = "https://$tenantdomain/$policyID/oauth2/v2.0/token?grant_type=$grant_type&refresh_token=$refresh_token&redirect_uri=$redirect_uri&client_id=$clientID"
    $response = Invoke-RestMethod -Method Post -Uri $baseURL
    $response

    $parsed = Parse-JWTtoken $response.access_token
    $parsed

    $iat = (([System.DateTimeOffset]::FromUnixTimeSeconds($parsed.iat)).DateTime).ToString("s")
    $exp = (([System.DateTimeOffset]::FromUnixTimeSeconds($parsed.exp)).DateTime).ToString("s")

    Write-Host "Access token was issued at $iat and will expire on $exp" -ForegroundColor Cyan

