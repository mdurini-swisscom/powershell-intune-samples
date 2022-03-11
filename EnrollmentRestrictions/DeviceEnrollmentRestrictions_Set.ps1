
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################



####################################################
    
Function Set-DeviceEnrollmentConfiguration(){
    
<#
.SYNOPSIS
This function is used to set the Device Enrollment Configuration resource using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets the Device Enrollment Configuration Resource
.EXAMPLE
Set-DeviceEnrollmentConfiguration -DEC_Id $DEC_Id -JSON $JSON
Sets the Device Enrollment Configuration using Graph API
.NOTES
NAME: Set-DeviceEnrollmentConfiguration
#>
    
[cmdletbinding()]
    
param
(
    $JSON,
    $DEC_Id
)
    
$graphApiVersion = "Beta"
$App_resource = "deviceManagement/deviceEnrollmentConfigurations"
        
    try {
    
        if(!$JSON){
    
        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break
    
        }
    
        elseif(!$DEC_Id){
    
        write-host "No Device Enrollment Configuration ID was passed to the function, provide a Device Enrollment Configuration ID" -f Red
        break
    
        }
    
        else {
    
        Test-JSON -JSON $JSON
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)/$DEC_Id"
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

$JSON = @"

{
    "@odata.type":"#microsoft.graph.deviceEnrollmentPlatformRestrictionsConfiguration",
    "displayName":"All Users",
    "description":"This is the default Device Type Restriction applied with the lowest priority to all users regardless of group membership.",

    "androidRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    },
    "androidForWorkRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":null,
    "osMaximumVersion":null
    },
    "iosRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    },
    "macRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":null,
    "osMaximumVersion":null
    },
    "windowsRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    },
    "windowsMobileRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    }

}

"@

####################################################

$DeviceEnrollmentConfigurations = Get-DeviceEnrollmentConfigurations

$PlatformRestrictions = ($DeviceEnrollmentConfigurations | Where-Object { ($_.id).contains("DefaultPlatformRestrictions") }).id

Set-DeviceEnrollmentConfiguration -DEC_Id $PlatformRestrictions -JSON $JSON
