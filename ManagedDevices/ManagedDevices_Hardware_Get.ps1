
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

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm' and managementAgent eq 'googleCloudDevicePolicyController'"
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

$ExportPath = Read-Host -Prompt "Please specify a path to export Managed Devices hardware data to e.g. C:\IntuneOutput"

    # If the directory path doesn't exist prompt user to create the directory

    if(!(Test-Path "$ExportPath")){

    Write-Host
    Write-Host "Path '$ExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow

    $Confirm = read-host

        if($Confirm -eq "y" -or $Confirm -eq "Y"){

        new-item -ItemType Directory -Path "$ExportPath" | Out-Null
        Write-Host

        }

        else {

        Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
        Write-Host
        break

        }

    }

Write-Host

####################################################

$Devices = Get-ManagedDevices

if($Devices){

    $Results = @()

    foreach($Device in $Devices){

    $DeviceID = $Device.id

    Write-Host "Device found:" $Device.deviceName -ForegroundColor Yellow
    Write-Host

    $uri = "https://graph.microsoft.com/beta/deviceManagement/manageddevices('$DeviceID')?`$select=hardwareinformation,iccid,udid,ethernetMacAddress"

    $DeviceInfo = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)

    $DeviceNoHardware = $Device | select * -ExcludeProperty hardwareInformation,deviceActionResults,userId,imei,manufacturer,model,isSupervised,isEncrypted,serialNumber,meid,subscriberCarrier,iccid,udid,ethernetMacAddress
    $HardwareExcludes = $DeviceInfo.hardwareInformation | select * -ExcludeProperty sharedDeviceCachedUsers,phoneNumber
    $OtherDeviceInfo = $DeviceInfo | select iccid,udid,ethernetMacAddress

        $Object = New-Object System.Object

            foreach($Property in $DeviceNoHardware.psobject.Properties){

                $Object | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.Value

            }

            foreach($Property in $HardwareExcludes.psobject.Properties){

                $Object | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.Value

            }

            foreach($Property in $OtherDeviceInfo.psobject.Properties){

                $Object | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.Value

            }

        $Results += $Object

        $Object

    }

    $Date = get-date

    $Output = "ManagedDeviceHardwareInfo_" + $Date.Day + "-" + $Date.Month + "-" + $Date.Year + "_" + $Date.Hour + "-" + $Date.Minute

    # Exporting Data to CSV file in provided directory
    $Results | Export-Csv "$ExportPath\$Output.csv" -NoTypeInformation
    write-host "CSV created in $ExportPath\$Output.csv..." -f cyan

}

else {

write-host "No Intune Managed Devices found..." -f green
Write-Host

}
