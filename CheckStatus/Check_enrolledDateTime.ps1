
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-AADUser(){

<#
.SYNOPSIS
This function is used to get AAD Users from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any users registered with AAD
.EXAMPLE
Get-AADUser
Returns all users registered with Azure AD
.EXAMPLE
Get-AADUser -userPrincipleName user@domain.com
Returns specific user by UserPrincipalName registered with Azure AD
.NOTES
NAME: Get-AADUser
#>

[cmdletbinding()]

param
(
    $userPrincipalName,
    $Property
)

# Defining Variables
$graphApiVersion = "v1.0"
$User_resource = "users"
    
    try {
        
        if($userPrincipalName -eq "" -or $userPrincipalName -eq $null){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        
        }

        else {
            
            if($Property -eq "" -or $Property -eq $null){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
            Write-Verbose $uri
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

            }

            else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
            Write-Verbose $uri
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            }

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

# Filter for the minimum number of minutes when the device enrolled into the Intune Service

# 1440 = 24 hours
$minutes = 1440

$minutesago = "{0:s}" -f (get-date).addminutes(0-$minutes) + "Z"

$CurrentTime = [System.DateTimeOffset]::Now

write-host "Checking if any Intune Managed Device Enrolled Date is within or equal to $minutes minutes..." -f Yellow
Write-Host
write-host "Minutes Ago:" $minutesago -f Magenta
Write-Host

    try {

    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=enrolledDateTime ge $minutesago"

    $Devices = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | sort deviceName

	$Devices = $Devices | ? { $_.managementAgent -ne "eas" }

        # If there are devices not synced in the past 30 days script continues
        
        if($Devices){

        $DeviceCount = @($Devices).count

        Write-Host "There are" $DeviceCount "devices enrolled in the past $minutes minutes..." -ForegroundColor green

        $Devices | foreach { $_.deviceName + " - " + ($_.managementAgent).toupper() + " - " + $_.userPrincipalName + " - " + $_.enrolledDateTime }

        Write-Host

            # Looping through all the devices returned
                       
            foreach($Device in $Devices){

            write-host "------------------------------------------------------------------"
            Write-Host

            $DeviceID = $Device.id
            $LSD = $Device.lastSyncDateTime
            $EDT = $Device.enrolledDateTime

            write-host "Device Name:"$Device.deviceName -f Green
            write-host "Management State:"$Device.managementState
            write-host "Operating System:"$Device.operatingSystem
            write-host "Device Type:"$Device.deviceType
            write-host "Last Sync Date Time:"$Device.lastSyncDateTime
            write-host "Enrolled Date Time:"$Device.enrolledDateTime
            write-host "Jail Broken:"$Device.jailBroken
            write-host "Compliance State:"$Device.complianceState
            write-host "Enrollment Type:"$Device.enrollmentType
            write-host "AAD Registered:"$Device.aadRegistered
            write-host "Management Agent:"$Device.managementAgent

            $EnrolledTime = [datetimeoffset]::Parse($EDT)

            $TimeDifference = $CurrentTime - $EnrolledTime

            $TotalMinutes = ($TimeDifference.TotalMinutes).tostring().split(".")[0]

            write-host
            write-host "Date Time difference is"$TotalMinutes "minutes from current date time..." -ForegroundColor Yellow
            Write-Host

            }

        }

        else {

        write-host "No Devices not checked in the last $minutes minutes found..." -f green
        Write-Host

        }

    }

    catch {

    Write-Host
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    Write-Host

    break

    }
