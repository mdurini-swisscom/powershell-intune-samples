
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-ManagedDevices(){

<#
.SYNOPSIS
This function is used to get Intune Managed Devices from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Intune Managed Device
.EXAMPLE
Get-ManagedDevices
Returns all managed devices but excludes EAS devices registered within the Intune Service
.EXAMPLE
Get-ManagedDevices -IncludeEAS
Returns all managed devices including EAS devices registered within the Intune Service
.NOTES
NAME: Get-ManagedDevices
#>

[cmdletbinding()]

param
(
    [switch]$IncludeEAS,
    [switch]$ExcludeMDM
)

# Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"

try {

    $Count_Params = 0

    if($IncludeEAS.IsPresent){ $Count_Params++ }
    if($ExcludeMDM.IsPresent){ $Count_Params++ }
        
        if($Count_Params -gt 1){

        write-warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
        Write-Host
        break

        }
        
        elseif($IncludeEAS){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

        }

        elseif($ExcludeMDM){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"

        }
        
        else {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
        Write-Warning "EAS Devices are excluded by default, please use -IncludeEAS if you want to include those devices"
        Write-Host

        }

        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
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

Function Set-ManagedDevice(){

<#
.SYNOPSIS
This function is used to set Managed Device property from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets a Managed Device property
.EXAMPLE
Set-ManagedDevice -id $id -ownerType company
Returns Managed Devices configured in Intune
.NOTES
NAME: Set-ManagedDevice
#>

[cmdletbinding()]

param
(
    $id,
    $ownertype
)


$graphApiVersion = "Beta"
$Resource = "deviceManagement/managedDevices"

    try {

        if($id -eq "" -or $id -eq $null){

        write-host "No Device id specified, please provide a device id..." -f Red
        break

        }
        
        if($ownerType -eq "" -or $ownerType -eq $null){

            write-host "No ownerType parameter specified, please provide an ownerType. Supported value personal or company..." -f Red
            Write-Host
            break

            }

        elseif($ownerType -eq "company"){

$JSON = @"

{
    ownerType:"company"
}

"@

                write-host
                write-host "Are you sure you want to change the device ownership to 'company' on this device? Y or N?"
                $Confirm = read-host

                if($Confirm -eq "y" -or $Confirm -eq "Y"){
            
                # Send Patch command to Graph to change the ownertype
                $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ID')"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $Json -ContentType "application/json"

                }

                else {

                Write-Host "Change of Device Ownership for the device $ID was cancelled..." -ForegroundColor Yellow
                Write-Host

                }
            
            }

        elseif($ownerType -eq "personal"){

$JSON = @"

{
    ownerType:"personal"
}

"@

                write-host
                write-host "Are you sure you want to change the device ownership to 'personal' on this device? Y or N?"
                $Confirm = read-host

                if($Confirm -eq "y" -or $Confirm -eq "Y"){
            
                # Send Patch command to Graph to change the ownertype
                $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ID')"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $Json -ContentType "application/json"

                }

                else {

                Write-Host "Change of Device Ownership for the device $ID was cancelled..." -ForegroundColor Yellow
                Write-Host

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

# Filter for the Managed Device of your choice
$ManagedDevice = Get-ManagedDevices | Where-Object { $_.deviceName -eq "IPADMINI4" }

if($ManagedDevice){

    if(@($ManagedDevice.count) -gt 1){

    Write-Host "More than 1 device was found, script supports single deviceID..." -ForegroundColor Red
    Write-Host
    break

    }

    else {

    write-host "Device Name:"$ManagedDevice.deviceName -ForegroundColor Cyan
    write-host "Management State:"$ManagedDevice.managementState
    write-host "Operating System:"$ManagedDevice.operatingSystem
    write-host "Device Type:"$ManagedDevice.deviceType
    write-host "Last Sync Date Time:"$ManagedDevice.lastSyncDateTime
    write-host "Jail Broken:"$ManagedDevice.jailBroken
    write-host "Compliance State:"$ManagedDevice.complianceState
    write-host "Enrollment Type:"$ManagedDevice.enrollmentType
    write-host "AAD Registered:"$ManagedDevice.aadRegistered
    write-host "Management Agent:"$ManagedDevice.managementAgent
    Write-Host "User Principal Name:"$ManagedDevice.userPrincipalName
    Write-Host "Owner Type:"$ManagedDevice.ownerType -ForegroundColor Yellow

    Set-ManagedDevice -id $ManagedDevice.id -ownertype personal

    }

}

else {

Write-Host "No Managed Device found..." -ForegroundColor Red
Write-Host

}
