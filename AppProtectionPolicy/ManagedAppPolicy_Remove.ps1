
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-ManagedAppPolicy(){

<#
.SYNOPSIS
This function is used to get managed app policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any managed app policies
.EXAMPLE
Get-ManagedAppPolicy
Returns any managed app policies configured in Intune
.NOTES
NAME: Get-ManagedAppPolicy
#>

[cmdletbinding()]

param
(
    $Name
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/managedAppPolicies"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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

Function Remove-ManagedAppPolicy(){

<#
.SYNOPSIS
This function is used to remove Managed App policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and removes managed app policies
.EXAMPLE
Remove-ManagedAppPolicy -id $id
Removes a managed app policy configured in Intune
.NOTES
NAME: Remove-ManagedAppPolicy
#>

[cmdletbinding()]

param
(
    $id
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/managedAppPolicies"

    try {

        if($id -eq "" -or $id -eq $null){

        write-host "No id specified for managed app policy, can't remove managed app policy..." -f Red
        write-host "Please specify id for managed app policy..." -f Red
        break

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$id"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete

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

$MAM = Get-ManagedAppPolicy -Name "Graph"

    if($MAM){

        if(@($MAM).count -gt 1){

        Write-Host "More than one App Protection policy has been found, please specify a single App Protection policy..." -ForegroundColor Red
        Write-Host

        }

        elseif(@($MAM).count -eq 1){

        Write-Host "Removing App Protection policy" $CP.displayName -ForegroundColor Yellow
        $MAM.displayname + ": " + $MAM.'@odata.type'
        $MAM.id
        Remove-ManagedAppPolicy -id $MAM.id

        }

    }

    else {

    Write-Host "App Protection Policy doesn't exist..." -ForegroundColor Red
    Write-Host

    }
