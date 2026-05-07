if (!(Get-InstalledModule Microsoft.Graph -ErrorAction SilentlyContinue)) {
    Write-Host "You need to install the Microsft.Graph module to run this script." -ForegroundColor Red
    Write-Host "Run 'Install-Module Microsoft.Graph -Scope CurrentUser' as an administrator" -ForegroundColor Red
    exit 1
}
 
if (!(Get-MgContext -ErrorAction SilentlyContinue)) {
    Connect-MgGraph -Scopes "Directory.Read.All,Group.Read.All"
}

# Query all dynamic groups and return those with a membership rule that contains memberOf rule
$dynamicMemberGroups =Get-MgGroup -Filter "groupTypes/any(c:c eq 'DynamicMembership')" -All | Where-Object { $_.MembershipRule -like "*memberOf*" } | Select-Object DisplayName, Id, MembershipRule, MembershipRuleProcessingState

# Create a GridView to allow user to choose specific or all groups to pause processing on
Write-Host "Select the dynamic groups you want to pause processing on. Hold down the Ctrl or Shift key to select multiple groups." -ForegroundColor Yellow
$selectedGroups = $dynamicMemberGroups | Out-GridView -Title "Select Dynamic Groups to Pause Processing" -PassThru

#Confirmation
Write-Host "Confirm you want to pause processing on the selected groups." -ForegroundColor Yellow
if ($selectedGroups.Count -gt 0) {
    $confirmation = Read-Host "Are you sure you want to pause processing on the selected groups? (Y/N)"
    if ($confirmation -ne "Y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "No groups selected. Exiting script." -ForegroundColor Red
    exit 1
}
# Pause processing on all memberOf rule dynamic groups selected by the user in the GridView
foreach ($group in $selectedGroups) {
    Update-MgGroup -GroupId $group.Id -MembershipRuleProcessingState "Paused"
    Write-Host "Paused processing for group: $($group.DisplayName)"
}

