
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-TermsAndConditions(){

<#
.SYNOPSIS
This function is used to get the Get Terms And Conditions intune resource from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets the Terms and Conditions Intune Resource
.EXAMPLE
Get-TermsAndConditions
Returns the Organization resource configured in Intune
.NOTES
NAME: Get-TermsAndConditions
#>

[cmdletbinding()]

param
(
    $Name
)

$graphApiVersion = "Beta"
$resource = "deviceManagement/termsAndConditions"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

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

Get-TermsAndConditions
