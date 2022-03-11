

<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-MobileAppConfigurations(){
    
<#
.SYNOPSIS
This function is used to get all Mobile App Configuration Policies using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets all Mobile App Configuration Policies from the itunes store
.EXAMPLE
Get-MobileAppConfigurations
Gets all Mobile App Configuration Policies configured in the Intune Service
.NOTES
NAME: Get-MobileAppConfigurations
#>

[cmdletbinding()]
    
$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileAppConfigurations?`$expand=assignments"
        
    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

    (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken).value


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

Function Get-TargetedManagedAppConfigurations(){
    
<#
.SYNOPSIS
This function is used to get all Targeted Managed App Configuration Policies using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets all Targeted Managed App Configuration Policies from the itunes store
.EXAMPLE
Get-TargetedManagedAppConfigurations
Gets all Targeted Managed App Configuration Policies configured in the Intune Service
.NOTES
NAME: Get-TargetedManagedAppConfigurations
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$false)]
    $PolicyId
)
    
$graphApiVersion = "Beta"
        
    try {

        if($PolicyId){

            $Resource = "deviceAppManagement/targetedManagedAppConfigurations('$PolicyId')?`$expand=apps,assignments"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken)

        }

        else {

            $Resource = "deviceAppManagement/targetedManagedAppConfigurations"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken).value

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

$AppConfigurations = Get-MobileAppConfigurations

if($AppConfigurations){

    foreach($AppConfiguration in $AppConfigurations){

        write-host "App Configuration Policy:"$AppConfiguration.displayName -f Yellow
        $AppConfiguration

        if($AppConfiguration.assignments){

            write-host "Getting App Configuration Policy assignment..." -f Cyan

            foreach($group in $AppConfiguration.assignments){

            (Get-AADGroup -id $group.target.GroupId).displayName

            }

        }

    }

}

else {

    Write-Host "No Mobile App Configurations found..." -ForegroundColor Red
    Write-Host

}

Write-Host

####################################################

$TargetedManagedAppConfigurations = Get-TargetedManagedAppConfigurations

if($TargetedManagedAppConfigurations){

    foreach($TargetedManagedAppConfiguration in $TargetedManagedAppConfigurations){

    write-host "Targeted Managed App Configuration Policy:"$TargetedManagedAppConfiguration.displayName -f Yellow

    $PolicyId = $TargetedManagedAppConfiguration.id

    $ManagedAppConfiguration = Get-TargetedManagedAppConfigurations -PolicyId $PolicyId
    $ManagedAppConfiguration

        if($ManagedAppConfiguration.assignments){

            write-host "Getting Targetd Managed App Configuration Policy assignment..." -f Cyan

            foreach($group in $ManagedAppConfiguration.assignments){

            (Get-AADGroup -id $group.target.GroupId).displayName

            }

        }

    Write-Host

    }

}

else {

    Write-Host "No Targeted Managed App Configurations found..." -ForegroundColor Red
    Write-Host

}