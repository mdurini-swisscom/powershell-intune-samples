
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

Function Get-AADUserManagedAppRegistrations(){

<#
.SYNOPSIS
This function is used to get an AAD User Managed App Registrations from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets a users Managed App Registrations registered with AAD
.EXAMPLE
Get-AADUser
Returns all Managed App Registration for a User registered with Azure AD
.EXAMPLE
Get-AADUserManagedAppRegistrations -id $id
Returns specific user by id registered with Azure AD
.NOTES
NAME: Get-AADUserManagedAppRegistrations
#>

[cmdletbinding()]

param
(
    $id
)

# Defining Variables
$graphApiVersion = "beta"
$User_resource = "users/$id/managedAppRegistrations"
    
    try {
        
        if(!$id){

        Write-Host "No AAD User ID was passed to the function, specify a valid AAD User ID" -ForegroundColor Red
        Write-Host
        break

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$User_resource"

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

write-host
write-host "User Principal Name:" -f Yellow
$UPN = Read-Host

$User = Get-AADUser -userPrincipalName $UPN

$UserID = $User.id

write-host
write-host "Display Name:"$User.displayName
write-host "User ID:"$User.id
write-host "User Principal Name:"$User.userPrincipalName
write-host

####################################################

$ManagedAppReg = Get-AADUserManagedAppRegistrations -id $UserID

    if($ManagedAppReg){

    $DeviceTag = $ManagedAppReg.deviceTag | sort -Unique

        # If user has only 1 device with managed application follow this flow
        if($DeviceTag.count -eq 1){

        $DeviceName = $ManagedAppReg.deviceName
    
        $uri = "https://graph.microsoft.com/beta/users('$UserID')/wipeManagedAppRegistrationByDeviceTag"

$JSON = @"

    {
        "deviceTag": "$DeviceTag"
    }

"@
            
            write-host "Are you sure you want to wipe application data on device $DeviceName`? Y or N?" -f Yellow
            $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

            }

            else {

            Write-Host
            Write-Host "Wipe application data for the device $DeviceName was cancelled..."
            Write-Host

            }

        }

        # If the user has more than 1 device with managed application follow this flow
        else {

        Write-Host "More than one device found with MAM Applications" -ForegroundColor Yellow
        Write-Host

        $MAM_Devices = $ManagedAppReg.deviceName | sort -Unique
        
        # Building menu from Array to show more than one device

        $menu = @{}

        for ($i=1;$i -le $MAM_Devices.count; $i++) 
        { Write-Host "$i. $($MAM_Devices[$i-1])" 
        $menu.Add($i,($MAM_Devices[$i-1]))}

        Write-Host
        [int]$ans = Read-Host 'Enter Device to wipe MAM Data (Numerical value)'
        $selection = $menu.Item($ans)

            If($selection){

            Write-Host "Device selected:"$selection
            Write-Host

            $SelectedDeviceTag = $ManagedAppReg | ? { $_.deviceName -eq "$Selection" } | sort -Unique | select -ExpandProperty deviceTag

            $uri = "https://graph.microsoft.com/beta/users('$UserID')/wipeManagedAppRegistrationByDeviceTag"

$JSON = @"

    {
        "deviceTag": "$SelectedDeviceTag"
    }

"@

                write-host "Are you sure you want to wipe application data on this device? Y or N?" -ForegroundColor Yellow
                $Confirm = read-host

                if($Confirm -eq "y" -or $Confirm -eq "Y"){

                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

                }

                else {

                Write-Host
                Write-Host "Wipe application data for this device was cancelled..."
                Write-Host

                }

            }

            else {

            Write-Host "No device selected..." -ForegroundColor Red

            }

        Write-Host

        }

    }
