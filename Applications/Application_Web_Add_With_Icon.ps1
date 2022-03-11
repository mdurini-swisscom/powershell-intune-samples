
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



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

Function Add-WebApplication(){

<#
.SYNOPSIS
This function is used to add a Web application using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a Web application
.EXAMPLE
Add-WebApplication -JSON $JSON -IconURL pathtourl
Adds a Web application into Intune using an icon from a URL
.NOTES
NAME: Add-WebApplication
#>

[cmdletbinding()]

param
(
    $JSON,
    $IconURL
)

$graphApiVersion = "Beta"
$App_resource = "deviceAppManagement/mobileApps"

    try {

        if(!$JSON){

        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }


        if($IconURL){

        write-verbose "Icon specified: $IconURL"

            if(!(test-path "$IconURL")){

            write-host "Icon Path '$IconURL' doesn't exist..." -ForegroundColor Red
            Write-Host "Please specify a valid path..." -ForegroundColor Red
            Write-Host
            break

            }

        $iconResponse = Invoke-WebRequest "$iconUrl"
        $base64icon = [System.Convert]::ToBase64String($iconResponse.Content)
        $iconExt = ([System.IO.Path]::GetExtension("$iconURL")).replace(".","")
        $iconType = "image/$iconExt"

        Write-Verbose "Updating JSON to add Icon Data"

        $U_JSON = ConvertFrom-Json $JSON

        $U_JSON.largeIcon.type = "$iconType"
        $U_JSON.largeIcon.value = "$base64icon"

        $JSON = ConvertTo-Json $U_JSON

        Write-Verbose $JSON

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

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
# Icon Location for Web Application
####################################################

$iconUrl_Bing = "C:\IntuneIcons\MyApps.PNG"

##################################################

$Bing = @"

{
    "@odata.type":"#microsoft.graph.webApp",
    "displayName":"Bing Web Search",
    "description":"Bing Web Search",
    "publisher":"Intune Admin",
    "isFeatured":false,
    "appUrl":"https://www.bing.com",
    "useManagedBrowser":false,
    largeIcon: {
    "@odata.type": "#microsoft.graph.mimeContent",
    "type": "$iconType",
    "value": "$base64icon"
    }
}

"@

##################################################

write-host "Publishing" ($Bing | ConvertFrom-Json).displayName -ForegroundColor Yellow

$Create_Bing = Add-WebApplication -JSON $Bing -IconURL "$iconUrl_Bing"

Write-Host "Application created as $($Create_Bing.displayName)/$($create_Bing.id)"
Write-Host
