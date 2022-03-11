﻿
<#
 
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-CorporateDeviceIdentifiers(){

<#
.SYNOPSIS
This function is used to get Corporate Device Identifiers from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets Corporate Device Identifiers
.EXAMPLE
Get-CorporateDeviceIdentifiers
Returns Corporate Device Identifiers configured in Intune
.NOTES
NAME: Get-CorporateDeviceIdentifiers
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$false)]
    $DeviceIdentifier
)


$graphApiVersion = "beta"

    try {

        if($DeviceIdentifier){

            $Resource = "deviceManagement/importedDeviceIdentities?`$filter=contains(importedDeviceIdentifier,'$DeviceIdentifier')"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        }

        else {

            $Resource = "deviceManagement/importedDeviceIdentities"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        }

    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

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

            # Defining Azure AD tenant name, this is the name of your Azure Active Directory (do not use the verified domain name)

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

$CDI = Get-CorporateDeviceIdentifiers

    if($CDI){

        $CDI

    }

    else {

    Write-Host "No Corporate Device Identifiers found..." -ForegroundColor Red

    }

Write-Host