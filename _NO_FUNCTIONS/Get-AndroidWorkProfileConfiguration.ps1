<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################



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

$DeviceEnrollmentConfigurations = Get-DeviceEnrollmentConfigurations

$AndroidEnterpriseConfig = $DeviceEnrollmentConfigurations | ? { $_.androidForWorkRestriction.platformBlocked -eq $false } | Sort-Object priority

write-host "-------------------------------------------------------------------"
Write-Host "Android Work Profile Configuration" -ForegroundColor Cyan
write-host "-------------------------------------------------------------------"
Write-Host

if($AndroidEnterpriseConfig){

    foreach($AndroidConfig in $AndroidEnterpriseConfig){

        $ConfigurationId = $AndroidConfig.id
        $ConfigurationDN = $AndroidConfig.displayName
        $ConfigurationP = $AndroidConfig.priority

        Write-Host "Android Work Profile '$ConfigurationDN' with priority $ConfigurationP configured..." -ForegroundColor Yellow

        if($ConfigurationP -eq 0){

            Write-Host "Android Work Profile enabled for All Users"

        }

        else {

            $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations/$ConfigurationId/assignments"

            $Assignments = (Invoke-RestMethod -Method Get -Uri $uri -Headers $authToken).value

            if($Assignments){

                Write-Host "AAD Groups assigned..."

                foreach($Assignment in $Assignments){

                    (Get-AADGroup -id $Assignment.target.groupId).displayName

                }

            }

            else {

                Write-Host "No Assignments for Platform restriction configured..." -ForegroundColor Red

            }

        }

    Write-Host

    }

}

else {

    Write-Host "No Android Work Profile Platform Restriction configured..." -ForegroundColor Red
    Write-Host

}