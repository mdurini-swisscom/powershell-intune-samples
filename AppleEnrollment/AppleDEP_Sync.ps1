<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Sync-AppleDEP(){

<#
.SYNOPSIS
Sync Intune tenant to Apple DEP service
.DESCRIPTION
Intune automatically syncs with the Apple DEP service once every 24hrs. This function synchronises your Intune tenant with the Apple DEP service.
.EXAMPLE
Sync-AppleDEP
.NOTES
NAME: Sync-AppleDEP
#>

[cmdletbinding()]

Param(
[parameter(Mandatory=$true)]
[string]$id
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$id/syncWithAppleDeviceEnrollmentProgram"

    try {

        $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        Invoke-RestMethod -Uri $SyncURI -Headers $authToken -Method Post

        }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-DEPOnboardingSettings {

<#
.SYNOPSIS
This function retrieves the DEP onboarding settings for your tenant. DEP Onboarding settings contain information such as Token ID, which is used to sync DEP and VPP
.DESCRIPTION
The function connects to the Graph API Interface and gets a retrieves the DEP onboarding settings.
.EXAMPLE
Get-DEPOnboardingSettings
Gets all DEP Onboarding Settings for each DEP token present in the tenant
.NOTES
NAME: Get-DEPOnboardingSettings
#>

[cmdletbinding()]

Param(
[parameter(Mandatory=$false)]
[string]$tokenid
)

$graphApiVersion = "beta"

    try {

        if ($tokenid){
        
        $Resource = "deviceManagement/depOnboardingSettings/$tokenid/"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
                
        }

        else {
        
        $Resource = "deviceManagement/depOnboardingSettings/"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value
        
        }
               
    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

} 

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