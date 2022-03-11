<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

param
(
[parameter(Mandatory=$false)]
$DeviceName

)

####################################################



####################################################

function Get-Win10IntuneManagedDevice {

<#
.SYNOPSIS
This gets information on Intune managed device
.DESCRIPTION
This gets information on Intune managed device
.EXAMPLE
Get-Win10IntuneManagedDevice
.NOTES
NAME: Get-Win10IntuneManagedDevice
#>

[cmdletbinding()]

param
(
[parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
[string]$deviceName
)
    
    $graphApiVersion = "beta"

    try {

        if($deviceName){

            $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
	        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" 

            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

        else {

            $Resource = "deviceManagement/managedDevices?`$filter=(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
	        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-IntuneManagedDevices error"
	}

}

####################################################

function Get-AADDeviceId {

<#
.SYNOPSIS
This gets an AAD device object id from the Intune AAD device id
.DESCRIPTION
This gets an AAD device object id from the Intune AAD device id
.EXAMPLE
Get-AADDeviceId
.NOTES
NAME: Get-AADDeviceId
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [string] $deviceId
)
    $graphApiVersion = "beta"
    $Resource = "devices"
	$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=deviceId eq '$deviceId'"

    try {
        $device = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        return $device.value."id"

	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-AADDeviceId error"
	}
}

####################################################

function Get-IntuneDevicePrimaryUser {

<#
.SYNOPSIS
This lists the Intune device primary user
.DESCRIPTION
This lists the Intune device primary user
.EXAMPLE
Get-IntuneDevicePrimaryUser
.NOTES
NAME: Get-IntuneDevicePrimaryUser
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [string] $deviceId
)
    
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices"
	$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" + "/" + $deviceId + "/users"

    try {
        
        $primaryUser = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        return $primaryUser.value."id"
        
	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-IntuneDevicePrimaryUser error"
	}
}

####################################################

function Get-AADDevicesRegisteredOwners {

<#
.SYNOPSIS
This lists the AAD devices registered owners
.DESCRIPTION
List of AAD device registered owners
.EXAMPLE
Get-AADDevicesRegisteredOwners
.NOTES
NAME: Get-AADDevicesRegisteredOwners
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [string] $deviceId
)
    $graphApiVersion = "beta"
    $Resource = "devices"
	$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$deviceId/registeredOwners"

    try {
        
        $registeredOwners = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        Write-Host "AAD Registered Owner:" -ForegroundColor Yellow

        if(@($registeredOwners.value).count -ge 1){

            for($i=0; $i -lt $registeredOwners.value.Count; $i++){
            
                Write-Host "Id:" $registeredOwners.value[$i]."id"
                Write-Host "Name:" $registeredOwners.value[$i]."displayName"
            
            }

        }

        else {

            Write-Host "No registered Owner found in Azure Active Directory..." -ForegroundColor Red
        
        }

	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-AADDevicesRegisteredOwners error"
	}
}

####################################################

function Get-AADDevicesRegisteredUsers {

<#
.SYNOPSIS
This lists the AAD devices registered users
.DESCRIPTION
List of AAD device registered users
.EXAMPLE
Get-AADDevicesRegisteredUsers
.NOTES
NAME: Get-AADDevicesRegisteredUsers
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [string] $deviceId
)
    $graphApiVersion = "beta"
    $Resource = "devices"
	$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" + "/$deviceId/registeredUsers"

    try {
        $registeredUsers = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        Write-Host "RegisteredUsers:" -ForegroundColor Yellow

        if(@($registeredUsers.value).count -ge 1){

            for($i=0; $i -lt $registeredUsers.value.Count; $i++)
            {

                Write-Host "Id:" $registeredUsers.value[$i]."id"
                Write-Host "Name:" $registeredUsers.value[$i]."displayName"
            }

        }

        else {

            Write-Host "No registered User found in Azure Active Directory..." -ForegroundColor Red
        
        }

	} catch {
		$ex = $_.Exception
		$errorResponse = $ex.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($errorResponse)
		$reader.BaseStream.Position = 0
		$reader.DiscardBufferedData()
		$responseBody = $reader.ReadToEnd();
		Write-Host "Response content:`n$responseBody" -f Red
		Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
		throw "Get-AADDevicesRegisteredUsers error"
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

    if($User -eq $null -or $User -eq "") {
        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host
    }

    # Getting the authorization token
    $global:authToken = Get-AuthToken -User $User
}

#endregion

####################################################

if($DeviceName){

    $Devices = Get-Win10IntuneManagedDevice -deviceName $DeviceName

}

else {

    $Devices = Get-Win10IntuneManagedDevice

}

####################################################

if($Devices){

    foreach($device in $Devices){

            Write-Host
            Write-Host "Device name:" $device."deviceName" -ForegroundColor Cyan
            Write-Host "Intune device id:" $device."id"
            
            $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -deviceId $device.id

            if($IntuneDevicePrimaryUser -eq $null){

                Write-Host "No Intune Primary User Id set for Intune Managed Device" $Device."deviceName" -f Red 

            }

            else {

                Write-Host "Intune Primary user id:" $IntuneDevicePrimaryUser

            }

            $aadDeviceId = Get-AADDeviceId -deviceId $device."azureActiveDirectoryDeviceId"
            Write-Host
            Get-AADDevicesRegisteredOwners -deviceId $aadDeviceId
            Write-Host
            Get-AADDevicesRegisteredUsers -deviceId $aadDeviceId

            Write-Host
            Write-Host "-------------------------------------------------------------------"
    
    }

}

else {

    Write-Host "No Windows 10 devices found..." -ForegroundColor Red

}

Write-Host