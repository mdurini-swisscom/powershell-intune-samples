
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-SoftwareUpdatePolicy(){

<#
.SYNOPSIS
This function is used to get Software Update policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Software Update policies
.EXAMPLE
Get-SoftwareUpdatePolicy -Windows10
Returns Windows 10 Software Update policies configured in Intune
.EXAMPLE
Get-SoftwareUpdatePolicy -iOS
Returns iOS update policies configured in Intune
.NOTES
NAME: Get-SoftwareUpdatePolicy
#>

[cmdletbinding()]

param
(
    [switch]$Windows10,
    [switch]$iOS
)

$graphApiVersion = "Beta"

    try {

        $Count_Params = 0

        if($iOS.IsPresent){ $Count_Params++ }
        if($Windows10.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){

        write-host "Multiple parameters set, specify a single parameter -iOS or -Windows10 against the function" -f Red

        }

        elseif($Count_Params -eq 0){

        Write-Host "Parameter -iOS or -Windows10 required against the function..." -ForegroundColor Red
        Write-Host
        break

        }

        elseif($Windows10){

        $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')&`$expand=groupAssignments"

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

        elseif($iOS){

        $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosUpdateConfiguration')&`$expand=groupAssignments"

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

$WSUPs = Get-SoftwareUpdatePolicy -Windows10

Write-Host "Software updates - Windows 10 Update Rings" -ForegroundColor Cyan
Write-Host

    if($WSUPs){

        foreach($WSUP in $WSUPs){

        write-host "Software Update Policy:"$WSUP.displayName -f Yellow
        $WSUP


        $TargetGroupIds = $WSUP.groupAssignments.targetGroupId

        write-host "Getting SoftwareUpdate Policy assignment..." -f Cyan

            if($TargetGroupIds){

                foreach($group in $TargetGroupIds){

                (Get-AADGroup -id $group).displayName

                }

            }

            else {

            Write-Host "No Software Update Policy Assignments found..." -ForegroundColor Red

            }

        }

    }

    else {

    Write-Host
    Write-Host "No Windows 10 Update Rings defined..." -ForegroundColor Red

    }

write-host

####################################################

$ISUPs = Get-SoftwareUpdatePolicy -iOS

Write-Host "Software updates - iOS Update Policies" -ForegroundColor Cyan
Write-Host

    if($ISUPs){

        foreach($ISUP in $ISUPs){

        write-host "Software Update Policy:"$ISUP.displayName -f Yellow
        $ISUP

        $TargetGroupIds = $ISUP.groupAssignments.targetGroupId

        write-host "Getting SoftwareUpdate Policy assignment..." -f Cyan

            if($TargetGroupIds){

                foreach($group in $TargetGroupIds){

                (Get-AADGroup -id $group).displayName

                }

            }

            else {

            Write-Host "No Software Update Policy Assignments found..." -ForegroundColor Red

            }

        }

    }

    else {

    Write-Host
    Write-Host "No iOS Software Update Rings defined..." -ForegroundColor Red

    }

Write-Host