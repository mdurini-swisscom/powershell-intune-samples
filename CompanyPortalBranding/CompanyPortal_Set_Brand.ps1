
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Set-IntuneBrand(){

<#
.SYNOPSIS
This function is used to set the Company Intune Brand resource using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets the Company Intune Brand Resource
.EXAMPLE
Set-IntuneBrand -JSON $JSON
Sets the Company Intune Brand using Graph API
.NOTES
NAME: Set-IntuneBrand
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$App_resource = "deviceManagement"

    try {

        if(!$JSON){

        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)"
        Invoke-RestMethod -Uri $uri -Method Patch -ContentType "application/json" -Body $JSON -Headers $authToken

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

Function Test-JSON(){

<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-AuthHeader
#>

param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
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

$iconUrl = "C:\Logos\Logo.png"

if(!(Test-Path "$iconUrl")){

Write-Host
write-host "Icon Path '$iconUrl' doesn't exist..." -ForegroundColor Red
write-host "Please specify a valid path to an icon..." -ForegroundColor Red
Write-Host
break

}

$iconResponse = Invoke-WebRequest "$iconUrl"
$base64icon = [System.Convert]::ToBase64String($iconResponse.Content)
$iconExt = ([System.IO.Path]::GetExtension("$iconURL")).replace(".","")
$iconType = "image/$iconExt"

####################################################

$JSON_Logo = @"
{
    "intuneBrand":{
    "displayName": "IT Company",
    "contactITName": "IT Admin",
    "contactITPhoneNumber": "01234567890",
    "contactITEmailAddress": "admin@itcompany.com",
    "contactITNotes": "some notes go here",
    "privacyUrl": "http://itcompany.com",
    "onlineSupportSiteUrl": "http://www.itcompany.com",
    "onlineSupportSiteName": "IT Company Website",
    "themeColor": {"r":0,"g":114,"b":198},
    "showLogo": true,
    lightBackgroundLogo: {
        "type": "$iconType`;base",
        "value": "$base64icon"
          },
    darkBackgroundLogo: {
        "type": "$iconType`;base",
        "value": "$base64icon"
          },
    "showNameNextToLogo": false,
    "@odata.type":"#microsoft.management.services.api.intuneBrand"
    }
}
"@

####################################################

Set-IntuneBrand -JSON $JSON_Logo
