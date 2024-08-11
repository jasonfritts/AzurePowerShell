
# Update your values to match Entra Smart Lockout settings
$entrathreshold = 5
$duration = 480 #8 minutes

# User to test against
$username = "user@contoso.com"

# Generate random password
function Get-RandomPassword {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Length = 12
    )
    
    $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+'
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] $Length
    $rng.GetBytes($bytes)
    
    for ($i = 0; $i -lt $Length; $i++) {
        $randomIndex = $bytes[$i] % $charSet.Length
        $password += $charSet[$randomIndex]
    }
    
    return $password
}

# Test sign in
function Test-Signin {
    param (
        [Parameter(Mandatory=$true)] [string]$username,
        [Parameter(Mandatory=$true)] [string]$password
        )


    $URL = "https://login.microsoftonline.com"
    $BodyParams = @{'resource' = 'https://management.azure.com'; 'client_id' = '04b07795-8ddb-461a-bbee-02f9e1bf7b46' ; 'client_info' = '1' ; 'grant_type' = 'password' ; 'username' = $username ; 'password' = $password ; 'scope' = 'openid'}
    $PostHeaders = @{'Accept' = 'application/json'; 'Content-Type' =  'application/x-www-form-urlencoded'}
    $webrequest = Invoke-WebRequest $URL/common/oauth2/token -Method Post -Headers $PostHeaders -Body $BodyParams -ErrorVariable RespErr 

            If ($webrequest.StatusCode -eq "200"){
                Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password"
                $webrequest = ""
                $fullresults += "$username : $password"
        }
        else{
                # Check the response for indication of MFA, tenant, valid user, etc...
                # Here is a referense list of all the Azure AD Authentication an Authorization Error Codes:
                # https://docs.microsoft.com/en-us/azure/active-directory/develop/reference-aadsts-error-codes

                # Standard invalid password
            If($RespErr -match "AADSTS50126")
                {
                Write-Host -ForegroundColor Cyan "AADSTS50126 Invalid username or password"
                }

                # Invalid Tenant Response
            ElseIf (($RespErr -match "AADSTS50128") -or ($RespErr -match "AADSTS50059"))
                {
                Write-Output "[*] WARNING! Tenant for account $username doesn't exist. Check the domain to make sure they are using Azure/O365 services."
                }

                # Invalid Username
            ElseIf($RespErr -match "AADSTS50034")
                {
                Write-Output "[*] WARNING! The user $username doesn't exist."
                }

                # Microsoft MFA response
            ElseIf(($RespErr -match "AADSTS50079") -or ($RespErr -match "AADSTS50076"))
                {
                Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password - NOTE: The response indicates MFA (Microsoft) is in use."
                $fullresults += "$username : $password"
                }
    
                # Conditional Access response (Based off of limited testing this seems to be the repsonse to DUO MFA)
            ElseIf($RespErr -match "AADSTS50158")
                {
                Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password - NOTE: The response indicates conditional access (MFA: DUO or other) is in use."
                $fullresults += "$username : $password"
                }

                # Locked out account or Smart Lockout in place
            ElseIf($RespErr -match "AADSTS50053")
                {
                Write-Host -ForegroundColor Yellow "[*] WARNING! The account $username appears to be locked."
                $lockout_count++
                }

                # Disabled account
            ElseIf($RespErr -match "AADSTS50057")
                {
                Write-Output "[*] WARNING! The account $username appears to be disabled."
                }
            
                # User password is expired
            ElseIf($RespErr -match "AADSTS50055")
                {
                Write-Host -ForegroundColor "green" "[*] SUCCESS! $username : $password - NOTE: The user's password is expired."
                $fullresults += "$username : $password"
                }

                # Unknown errors
            Else
                {
                Write-Output "[*] Got an error we haven't seen yet for user $username"
                $RespErr
                }
        }


        }

# Force smart lockout to occur    
for ($i = 0; $i -lt $entrathreshold*2; $i++) {

    $password = Get-RandomPassword -Length 12
    Test-Signin -username $username -password $password
        
}


# NOTES
## For PTA customer, to reset smart lockout you must have password reset + password writeback enabled, otherwise user must wait
## for cloud smart lockout duration to expire

# Check on-prem AD user properties
# Check on-prem user status, if lockout settings are set per best practice, on-premuser should not be locked even
# when seeing cloud lockout.  If sspr\password writeback occurs will see this in logs as a unlock (4767)\passwordreset(4724).

$user = Get-ADUser -Identity "user" -Properties pwdLastSet, LockedOut
$pwdLastSet = $user.pwdLastSet
([datetime]::FromFileTime($pwdLastSet)).DateTime
$user.LockedOut

