
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-IntuneMAMApplication(){

<#
.SYNOPSIS
This function is used to get MAM applications from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any MAM applications
.EXAMPLE
Get-IntuneMAMApplication -Android
Returns any Android MAM applications configured in Intune
Get-IntuneMAMApplication -iOS
Returns any iOS MAM applications configured in Intune
Get-IntuneMAMApplication
Returns all MAM applications configured in Intune
.NOTES
NAME: Get-IntuneMAMApplication
#>

[cmdletbinding()]

param
(
[switch]$Android,
[switch]$iOS
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps"

    try {

        $Count_Params = 0

        if($Android.IsPresent){ $Count_Params++ }
        if($iOS.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){

        write-host "Multiple parameters set, specify a single parameter -Android or -iOS against the function" -f Red
        Write-Host

        }
        
        elseif($Android){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | ? { ($_.'@odata.type').Contains("managedAndroidStoreApp") }

        }

        elseif($iOS){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | ? { ($_.'@odata.type').Contains("managedIOSStoreApp") }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | ? { ($_.'@odata.type').Contains("managed") }

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

$APP_iOS = Get-IntuneMAMApplication -iOS | Sort-Object displayName

$APP_Android = Get-IntuneMAMApplication -Android | Sort-Object displayName

Write-Host "Managed iOS Store Applications" -f Yellow
Write-Host

    $APP_iOS | ForEach-Object {

    Write-Host "DisplayName:" $_.displayName -ForegroundColor Cyan
    $_.'@odata.type'
    $_.bundleId
    Write-Host

    }

####################################################

Write-Host "Managed Android Store Applications" -f Yellow
Write-Host

    $APP_Android | ForEach-Object {

    Write-Host "DisplayName:" $_.displayName -ForegroundColor Cyan
    $_.'@odata.type'
    $_.packageId
    Write-Host

    }

Write-Host