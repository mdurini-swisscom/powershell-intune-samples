
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Sync-AppleVPP(){

<#
.SYNOPSIS
Sync Intune tenant to Apple VPP service
.DESCRIPTION
Intune automatically syncs with the Apple VPP service once every 15hrs. This function synchronises your Intune tenant with the Apple VPP service.
.EXAMPLE
Sync-AppleVPP
.NOTES
NAME: Sync-AppleVPP
#>

[cmdletbinding()]

Param(
[parameter(Mandatory=$true)]
[string]$id
)


$graphApiVersion = "beta"
$Resource = "deviceAppManagement/vppTokens/$id/syncLicenses"


    try {

        $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"

        Write-Host "Syncing $TokenDisplayName with Apple VPP service..."
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

Function Get-VPPToken{

<#
.SYNOPSIS
Gets all Apple VPP Tokens
.DESCRIPTION
Gets all Apple VPP Tokens configured in the Service.
.EXAMPLE
Get-VPPToken
.NOTES
NAME: Get-VPPToken
#>

[cmdletbinding()]

Param(
[parameter(Mandatory=$false)]
[string]$tokenid
)

$graphApiVersion = "beta"
$Resource = "deviceAppManagement/vppTokens"
    
    try {
                
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value
            
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

$tokens = (Get-VPPToken)

#region menu

if($tokens){

$tokencount = @($tokens).count

Write-Host "VPP tokens found: $tokencount" -ForegroundColor Yellow
Write-Host

    if($tokencount -gt 1){

    $VPP_Tokens = $tokens.Displayname| Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $VPP_Tokens.count; $i++) 
    { Write-Host "$i. $($VPP_Tokens[$i-1])" 
    $menu.Add($i,($VPP_Tokens[$i-1]))}

    Write-Host
    [int]$ans = Read-Host 'Select the token you wish to sync (numerical value)'
    $selection = $menu.Item($ans)
    Write-Host

        if($selection){

            $SelectedToken = $tokens | Where-Object { $_.DisplayName -eq "$Selection" }

            $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id

            $TokenDisplayName = $SelectedToken.displayName

        }

    }

    elseif($tokencount -eq 1){

        $SelectedTokenId = $tokens.id
        $TokenDisplayName = $tokens.displayName

    }

}

else {

    Write-Host
    write-host "No VPP tokens found!" -f Yellow
    break

}

$SyncID = $SelectedTokenId

$VPPToken = Get-VPPToken | Where-Object { $_.id -eq "$SyncID"}

if ($VPPToken.lastSyncStatus -eq "Completed") {
    
    $VPPSync = Sync-AppleVPP -id $SyncID
    Write-Host "Success: " -ForegroundColor Green -NoNewline
    Write-Host "$TokenDisplayName sync initiated."

}

else {
    
    $LastSyncStatus = $VPPToken.lastSyncStatus
    Write-Warning "'$TokenDisplayName' sync status '$LastSyncStatus'..."

}

Write-Host