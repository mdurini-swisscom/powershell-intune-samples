
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Add-ManagedAppPolicy(){

<#
.SYNOPSIS
This function is used to add an Managed App policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a Managed App policy
.EXAMPLE
Add-ManagedAppPolicy -JSON $JSON
Adds a Managed App policy in Intune
.NOTES
NAME: Add-ManagedAppPolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/managedAppPolicies"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for a Managed App Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

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
    write-host
    break

    }

}

####################################################

Function Assign-ManagedAppPolicy(){

<#
.SYNOPSIS
This function is used to assign an AAD group to a Managed App Policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and assigns a Managed App Policy with an AAD Group
.EXAMPLE
Assign-ManagedAppPolicy -Id $Id -TargetGroupId $TargetGroupId -OS Android
Assigns an AAD Group assignment to an Android App Protection Policy in Intune
.EXAMPLE
Assign-ManagedAppPolicy -Id $Id -TargetGroupId $TargetGroupId -OS iOS
Assigns an AAD Group assignment to an iOS App Protection Policy in Intune
.NOTES
NAME: Assign-ManagedAppPolicy
#>

[cmdletbinding()]

param
(
    $Id,
    $TargetGroupId,
    $OS
)

$graphApiVersion = "Beta"
    
    try {

        if(!$Id){

        write-host "No Policy Id specified, specify a valid Application Id" -f Red
        break

        }

        if(!$TargetGroupId){

        write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        break

        }

$JSON = @"

{
    "assignments":[
    {
        "target":
        {
            "groupId":"$TargetGroupId",
            "@odata.type":"#microsoft.graph.groupAssignmentTarget"
        }
    }
    ]
}

"@

        if($OS -eq "" -or $OS -eq $null){

        write-host "No OS parameter specified, please provide an OS. Supported value Android or iOS..." -f Red
        Write-Host
        break

        }

        elseif($OS -eq "Android"){

        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections('$ID')/assign"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

        }

        elseif($OS -eq "iOS"){

        $uri = "https://graph.microsoft.com/$graphApiVersion/deviceAppManagement/iosManagedAppProtections('$ID')/assign"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

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

Function Test-JSON(){

<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-AuthHeader
#>

param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
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

# Setting AAD Group

$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where policies will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id

    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
    Write-Host
    exit

    }

Write-Host

##################################################

$iOS = @"

{
  "@odata.type": "#microsoft.graph.iosManagedAppProtection",
  "displayName": "Graph MAM iOS Policy Assigned",
  "description": "Graph MAM iOS Policy Assigned",
  "periodOfflineBeforeAccessCheck": "PT12H",
  "periodOnlineBeforeAccessCheck": "PT30M",
  "allowedInboundDataTransferSources": "allApps",
  "allowedOutboundDataTransferDestinations": "allApps",
  "organizationalCredentialsRequired": false,
  "allowedOutboundClipboardSharingLevel": "allApps",
  "dataBackupBlocked": true,
  "deviceComplianceRequired": true,
  "managedBrowserToOpenLinksRequired": true,
  "saveAsBlocked": true,
  "periodOfflineBeforeWipeIsEnforced": "P90D",
  "pinRequired": true,
  "maximumPinRetries": 5,
  "simplePinBlocked": true,
  "minimumPinLength": 4,
  "pinCharacterSet": "numeric",
  "allowedDataStorageLocations": [],
  "contactSyncBlocked": true,
  "printBlocked": true,
  "fingerprintBlocked": true,
  "appDataEncryptionType": "afterDeviceRestart",

  "apps": [
    {
        "mobileAppIdentifier": {
        "@odata.type": "#microsoft.graph.iosMobileAppIdentifier",
        "bundleId": "com.microsoft.office.outlook"
        }
    },
    {
        "mobileAppIdentifier": {
        "@odata.type": "#microsoft.graph.iosMobileAppIdentifier",
        "bundleId": "com.microsoft.office.excel"
        }
    }

    ]
}

"@

####################################################

$Android = @"

{
  "@odata.type": "#microsoft.graph.androidManagedAppProtection",
  "displayName": "Graph MAM Android Policy Assigned",
  "description": "Graph MAM Android Policy Assigned",
  "periodOfflineBeforeAccessCheck": "PT12H",
  "periodOnlineBeforeAccessCheck": "PT30M",
  "allowedInboundDataTransferSources": "allApps",
  "allowedOutboundDataTransferDestinations": "allApps",
  "organizationalCredentialsRequired": false,
  "allowedOutboundClipboardSharingLevel": "allApps",
  "dataBackupBlocked": true,
  "deviceComplianceRequired": true,
  "managedBrowserToOpenLinksRequired": true,
  "saveAsBlocked": true,
  "periodOfflineBeforeWipeIsEnforced": "P90D",
  "pinRequired": true,
  "maximumPinRetries": 5,
  "simplePinBlocked": true,
  "minimumPinLength": 4,
  "pinCharacterSet": "numeric",
  "allowedDataStorageLocations": [],
  "contactSyncBlocked": true,
  "printBlocked": true,
  "fingerprintBlocked": true,
  "appDataEncryptionType": "afterDeviceRestart",

  "apps": [
    {
        "mobileAppIdentifier": {
        "@odata.type": "#microsoft.graph.androidMobileAppIdentifier",
        "packageId": "com.microsoft.office.outlook"
        }
    },
    {
        "mobileAppIdentifier": {
        "@odata.type": "#microsoft.graph.androidMobileAppIdentifier",
        "packageId": "com.microsoft.office.excel"
        }
    }

    ]
}

"@

####################################################

Write-Host "Adding App Protection Policies to Intune..." -ForegroundColor Cyan
Write-Host

Write-Host "Adding iOS Managed App Policy from JSON..." -ForegroundColor Yellow
Write-Host "Creating Policy via Graph"

$CreateResult = Add-ManagedAppPolicy -Json $iOS
write-host "Policy created with id" $CreateResult.id

$MAM_PolicyID = $CreateResult.id

$Assign_Policy = Assign-ManagedAppPolicy -Id $MAM_PolicyID -TargetGroupId $TargetGroupId -OS iOS
Write-Host "Assigned '$AADGroup' to $($CreateResult.displayName)/$($CreateResult.id)"

Write-Host

write-host "Adding Android Managed App Policy from JSON..." -f Yellow
Write-Host "Creating Policy via Graph"

$CreateResult = Add-ManagedAppPolicy -Json $Android
write-host "Policy created with id" $CreateResult.id

$MAM_PolicyID = $CreateResult.id

$Assign_Policy = Assign-ManagedAppPolicy -Id $MAM_PolicyID -TargetGroupId $TargetGroupId -OS Android
Write-Host "Assigned '$AADGroup' to $($CreateResult.displayName)/$($CreateResult.id)"

Write-Host
