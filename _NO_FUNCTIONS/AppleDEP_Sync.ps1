<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################



####################################################



####################################################

#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining User Principal Name if not present

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################

$tokens = (Get-DEPOnboardingSettings)

if($tokens){

$tokencount = @($tokens).count

Write-Host "DEP tokens found: $tokencount"
Write-Host

    if($tokencount -gt 1){

    $DEP_Tokens = $tokens.tokenName | Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $DEP_Tokens.count; $i++) 
    { Write-Host "$i. $($DEP_Tokens[$i-1])" 
    $menu.Add($i,($DEP_Tokens[$i-1]))}

    Write-Host
    [int]$ans = Read-Host 'Select the token you wish to sync (numerical value)'
    $selection = $menu.Item($ans)
    Write-Host

        if($selection){

        $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$Selection" }

        $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id

        $id = $SelectedTokenId

        }

    }

    elseif ($tokencount -eq 1){

        $id = (Get-DEPOnboardingSettings).id

        }

    else {
    
        Write-Host
        Write-Warning "No DEP tokens found!"
        break

    }

    $LastSync = (Get-DEPOnboardingSettings -tokenid $id).lastSyncTriggeredDateTime
    $TokenDisplayName = (Get-DEPOnboardingSettings -tokenid $id).TokenName

    $CurrentTime = [System.DateTimeOffset]::Now

    $LastSyncTime = [datetimeoffset]::Parse($LastSync)

    $TimeDifference = ($CurrentTime - $LastSyncTime)

    $TotalMinutes = ($TimeDifference.Minutes)

    $RemainingTimeToSync = (15 - [int]$TotalMinutes)

        if ($RemainingTimeToSync -gt 0 -AND $RemainingTimeToSync -lt 16) {

            Write-Warning "Syncing in progress. You can retry sync in $RemainingTimeToSync minutes"
            Write-Host

        } 
           
        else {
    
            Write-Host "Syncing '$TokenDisplayName' DEP token with Apple DEP service..."
            Sync-AppleDEP $id

        }

}

else {

    Write-Warning "No DEP tokens found!"
    Write-Host
    break

}