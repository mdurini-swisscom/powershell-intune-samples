
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Add-DeviceConfigurationPolicy(){

<#
.SYNOPSIS
This function is used to add an device configuration policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device configuration policy
.EXAMPLE
Add-DeviceConfigurationPolicy -JSON $JSON
Adds a device configuration policy in Intune
.NOTES
NAME: Add-DeviceConfigurationPolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceConfigurations"
Write-Verbose "Resource: $DCP_resource"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

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

Function Add-DeviceConfigurationPolicyAssignment(){

    <#
    .SYNOPSIS
    This function is used to add a device configuration policy assignment using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy assignment
    .EXAMPLE
    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId -AssignmentType Included
    Adds a device configuration policy assignment in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicyAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ConfigurationPolicyId,
    
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $TargetGroupId,
    
        [parameter(Mandatory=$true)]
        [ValidateSet("Included","Excluded")]
        [ValidateNotNullOrEmpty()]
        [string]$AssignmentType
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceConfigurations/$ConfigurationPolicyId/assign"
        
        try {
    
            if(!$ConfigurationPolicyId){
    
                write-host "No Configuration Policy Id specified, specify a valid Configuration Policy Id" -f Red
                break
    
            }
    
            if(!$TargetGroupId){
    
                write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
                break
    
            }
    
            # Checking if there are Assignments already configured in the Policy
            $DCPA = Get-DeviceConfigurationPolicyAssignment -id $ConfigurationPolicyId
    
            $TargetGroups = @()
    
            if(@($DCPA).count -ge 1){
                
                if($DCPA.targetGroupId -contains $TargetGroupId){
    
                Write-Host "Group with Id '$TargetGroupId' already assigned to Policy..." -ForegroundColor Red
                Write-Host
                break
    
                }
    
                # Looping through previously configured assignements
    
                $DCPA | foreach {
    
                $TargetGroup = New-Object -TypeName psobject
         
                    if($_.excludeGroup -eq $true){
    
                        $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'
         
                    }
         
                    else {
         
                        $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'
         
                    }
    
                $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value $_.targetGroupId
    
                $Target = New-Object -TypeName psobject
                $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup
    
                $TargetGroups += $Target
    
                }
    
                # Adding new group to psobject
                $TargetGroup = New-Object -TypeName psobject
    
                    if($AssignmentType -eq "Excluded"){
    
                        $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'
         
                    }
         
                    elseif($AssignmentType -eq "Included") {
         
                        $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'
         
                    }
         
                $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"
    
                $Target = New-Object -TypeName psobject
                $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup
    
                $TargetGroups += $Target
    
            }
    
            else {
    
                # No assignments configured creating new JSON object of group assigned
                
                $TargetGroup = New-Object -TypeName psobject
    
                    if($AssignmentType -eq "Excluded"){
    
                        $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'
         
                    }
         
                    elseif($AssignmentType -eq "Included") {
         
                        $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'
         
                    }
         
                $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"
    
                $Target = New-Object -TypeName psobject
                $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup
    
                $TargetGroups = $Target
    
            }
    
        # Creating JSON object to pass to Graph
        $Output = New-Object -TypeName psobject
    
        $Output | Add-Member -MemberType NoteProperty -Name 'assignments' -Value @($TargetGroups)
    
        $JSON = $Output | ConvertTo-Json -Depth 3
    
        # POST to Graph Service
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
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

Function Get-DeviceConfigurationPolicyAssignment(){

    <#
    .SYNOPSIS
    This function is used to get device configuration policy assignment from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets a device configuration policy assignment
    .EXAMPLE
    Get-DeviceConfigurationPolicyAssignment $id guid
    Returns any device configuration policy assignment configured in Intune
    .NOTES
    NAME: Get-DeviceConfigurationPolicyAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true,HelpMessage="Enter id (guid) for the Device Configuration Policy you want to check assignment")]
        $id
    )
    
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"
    
        try {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/groupAssignments"
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

$iOS = @"

{
    "@odata.type": "#microsoft.graph.iosGeneralDeviceConfiguration",
    "description": "",
    "displayName": "iOS Device Restriction Policy",
    "accountBlockModification": false,
    "activationLockAllowWhenSupervised": false,
    "airDropBlocked": false,
    "airDropForceUnmanagedDropTarget": false,
    "airPlayForcePairingPasswordForOutgoingRequests": false,
    "appleWatchBlockPairing": false,
    "appleWatchForceWristDetection": false,
    "appleNewsBlocked": false,
    "appsSingleAppModeBundleIds": [],
    "appsVisibilityList": [],
    "appsVisibilityListType": "none",
    "appStoreBlockAutomaticDownloads": false,
    "appStoreBlocked": false,
    "appStoreBlockInAppPurchases": false,
    "appStoreBlockUIAppInstallation": false,
    "appStoreRequirePassword": false,
    "bluetoothBlockModification": false,
    "cameraBlocked": false,
    "cellularBlockDataRoaming": false,
    "cellularBlockGlobalBackgroundFetchWhileRoaming": false,
    "cellularBlockPerAppDataModification": false,
    "cellularBlockVoiceRoaming": false,
    "certificatesBlockUntrustedTlsCertificates": false,
    "classroomAppBlockRemoteScreenObservation": false,
    "compliantAppsList": [],
    "compliantAppListType": "none",
    "configurationProfileBlockChanges": false,
    "definitionLookupBlocked": false,
    "deviceBlockEnableRestrictions": false,
    "deviceBlockEraseContentAndSettings": false,
    "deviceBlockNameModification": false,
    "diagnosticDataBlockSubmission": false,
    "diagnosticDataBlockSubmissionModification": false,
    "documentsBlockManagedDocumentsInUnmanagedApps": false,
    "documentsBlockUnmanagedDocumentsInManagedApps": false,
    "emailInDomainSuffixes": [],
    "enterpriseAppBlockTrust": false,
    "enterpriseAppBlockTrustModification": false,
    "faceTimeBlocked": false,
    "findMyFriendsBlocked": false,
    "gamingBlockGameCenterFriends": true,
    "gamingBlockMultiplayer": false,
    "gameCenterBlocked": false,
    "hostPairingBlocked": false,
    "iBooksStoreBlocked": false,
    "iBooksStoreBlockErotica": false,
    "iCloudBlockActivityContinuation": false,
    "iCloudBlockBackup": true,
    "iCloudBlockDocumentSync": true,
    "iCloudBlockManagedAppsSync": false,
    "iCloudBlockPhotoLibrary": false,
    "iCloudBlockPhotoStreamSync": true,
    "iCloudBlockSharedPhotoStream": false,
    "iCloudRequireEncryptedBackup": false,
    "iTunesBlockExplicitContent": false,
    "iTunesBlockMusicService": false,
    "iTunesBlockRadio": false,
    "keyboardBlockAutoCorrect": false,
    "keyboardBlockPredictive": false,
    "keyboardBlockShortcuts": false,
    "keyboardBlockSpellCheck": false,
    "kioskModeAllowAssistiveSpeak": false,
    "kioskModeAllowAssistiveTouchSettings": false,
    "kioskModeAllowAutoLock": false,
    "kioskModeAllowColorInversionSettings": false,
    "kioskModeAllowRingerSwitch": false,
    "kioskModeAllowScreenRotation": false,
    "kioskModeAllowSleepButton": false,
    "kioskModeAllowTouchscreen": false,
    "kioskModeAllowVoiceOverSettings": false,
    "kioskModeAllowVolumeButtons": false,
    "kioskModeAllowZoomSettings": false,
    "kioskModeAppStoreUrl": null,
    "kioskModeRequireAssistiveTouch": false,
    "kioskModeRequireColorInversion": false,
    "kioskModeRequireMonoAudio": false,
    "kioskModeRequireVoiceOver": false,
    "kioskModeRequireZoom": false,
    "kioskModeManagedAppId": null,
    "lockScreenBlockControlCenter": false,
    "lockScreenBlockNotificationView": false,
    "lockScreenBlockPassbook": false,
    "lockScreenBlockTodayView": false,
    "mediaContentRatingAustralia": null,
    "mediaContentRatingCanada": null,
    "mediaContentRatingFrance": null,
    "mediaContentRatingGermany": null,
    "mediaContentRatingIreland": null,
    "mediaContentRatingJapan": null,
    "mediaContentRatingNewZealand": null,
    "mediaContentRatingUnitedKingdom": null,
    "mediaContentRatingUnitedStates": null,
    "mediaContentRatingApps": "allAllowed",
    "messagesBlocked": false,
    "notificationsBlockSettingsModification": false,
    "passcodeBlockFingerprintUnlock": false,
    "passcodeBlockModification": false,
    "passcodeBlockSimple": true,
    "passcodeExpirationDays": null,
    "passcodeMinimumLength": 4,
    "passcodeMinutesOfInactivityBeforeLock": null,
    "passcodeMinutesOfInactivityBeforeScreenTimeout": null,
    "passcodeMinimumCharacterSetCount": null,
    "passcodePreviousPasscodeBlockCount": null,
    "passcodeSignInFailureCountBeforeWipe": null,
    "passcodeRequiredType": "deviceDefault",
    "passcodeRequired": true,
    "podcastsBlocked": false,
    "safariBlockAutofill": false,
    "safariBlockJavaScript": false,
    "safariBlockPopups": false,
    "safariBlocked": false,
    "safariCookieSettings": "browserDefault",
    "safariManagedDomains": [],
    "safariPasswordAutoFillDomains": [],
    "safariRequireFraudWarning": false,
    "screenCaptureBlocked": false,
    "siriBlocked": false,
    "siriBlockedWhenLocked": false,
    "siriBlockUserGeneratedContent": false,
    "siriRequireProfanityFilter": false,
    "spotlightBlockInternetResults": false,
    "voiceDialingBlocked": false,
    "wallpaperBlockModification": false
}

"@

####################################################

$Android = @"

{
    "@odata.type": "#microsoft.graph.androidGeneralDeviceConfiguration",
    "description": "",
    "displayName": "Android Device Restriction Policy",
    "appsBlockClipboardSharing": false,
    "appsBlockCopyPaste": false,
    "appsBlockYouTube": false,
    "bluetoothBlocked": false,
    "cameraBlocked": false,
    "cellularBlockDataRoaming": true,
    "cellularBlockMessaging": false,
    "cellularBlockVoiceRoaming": false,
    "cellularBlockWiFiTethering": false,
    "compliantAppsList": [],
    "compliantAppListType": "none",
    "diagnosticDataBlockSubmission": false,
    "locationServicesBlocked": false,
    "googleAccountBlockAutoSync": false,
    "googlePlayStoreBlocked": false,
    "kioskModeBlockSleepButton": false,
    "kioskModeBlockVolumeButtons": false,
    "kioskModeManagedAppId": null,
    "nfcBlocked": false,
    "passwordBlockFingerprintUnlock": true,
    "passwordBlockTrustAgents": false,
    "passwordExpirationDays": null,
    "passwordMinimumLength": 4,
    "passwordMinutesOfInactivityBeforeScreenTimeout": null,
    "passwordPreviousPasswordBlockCount": null,
    "passwordSignInFailureCountBeforeFactoryReset": null,
    "passwordRequiredType": "deviceDefault",
    "passwordRequired": true,
    "powerOffBlocked": false,
    "factoryResetBlocked": false,
    "screenCaptureBlocked": false,
    "deviceSharingBlocked": false,
    "storageBlockGoogleBackup": true,
    "storageBlockRemovableStorage": false,
    "storageRequireDeviceEncryption": true,
    "storageRequireRemovableStorageEncryption": true,
    "voiceAssistantBlocked": false,
    "voiceDialingBlocked": false,
    "webBrowserAllowPopups": false,
    "webBrowserBlockAutofill": false,
    "webBrowserBlockJavaScript": false,
    "webBrowserBlocked": false,
    "webBrowserCookieSettings": "browserDefault",
    "wiFiBlocked": false
}

"@

####################################################

# Setting application AAD Group to assign Policy

$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where policies will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id

    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
    Write-Host
    exit

    }

####################################################

Write-Host "Adding Android Device Restriction Policy from JSON..." -ForegroundColor Yellow

$CreateResult_Android = Add-DeviceConfigurationPolicy -JSON $Android

Write-Host "Device Restriction Policy created as" $CreateResult_Android.id
write-host
write-host "Assigning Device Restriction Policy to AAD Group '$AADGroup'" -f Cyan

$Assign_Android = Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $CreateResult_Android.id -TargetGroupId $TargetGroupId -AssignmentType Included

Write-Host "Assigned '$AADGroup' to $($CreateResult_Android.displayName)/$($CreateResult_Android.id)"
Write-Host

####################################################

Write-Host "Adding iOS Device Restriction Policy from JSON..." -ForegroundColor Yellow
Write-Host

$CreateResult_iOS = Add-DeviceConfigurationPolicy -JSON $iOS

Write-Host "Device Restriction Policy created as" $CreateResult_iOS.id
write-host
write-host "Assigning Device Restriction Policy to AAD Group '$AADGroup'" -f Cyan

$Assign_iOS = Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $CreateResult_iOS.id -TargetGroupId $TargetGroupId -AssignmentType Included

Write-Host "Assigned '$AADGroup' to $($CreateResult_iOS.displayName)/$($CreateResult_iOS.id)"
Write-Host
