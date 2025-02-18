﻿
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-DeviceConfigurationPolicy(){

<#
.SYNOPSIS
This function is used to get device configuration policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device configuration policies
.EXAMPLE
Get-DeviceConfigurationPolicy
Returns any device configuration policies configured in Intune
.NOTES
NAME: Get-DeviceConfigurationPolicy
#>

[cmdletbinding()]

param
(
    $name
)

$graphApiVersion = "beta"
$DCP_resource = "deviceManagement/deviceConfigurations"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=displayName eq '$name'"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
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

Function Add-DeviceConfigurationPolicyAssignment(){

<#
.SYNOPSIS
This function is used to add a device configuration policy assignment using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device configuration policy assignment
.EXAMPLE
Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId
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

# Setting application AAD Group to assign Policy

$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where policies will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id


    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

        Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
        Write-Host
        exit

    }

####################################################

$PolicyName = "Device Configuration Policy Name"

$DCP = Get-DeviceConfigurationPolicy -name "$PolicyName"

if($DCP){

    $Assignment = Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $DCP.id -TargetGroupId $TargetGroupId -AssignmentType Included
    Write-Host "Assigned '$AADGroup' to $($DCP.displayName)/$($DCP.id)" -ForegroundColor Green
    Write-Host

}

else {

    Write-Host "Can't find Device Configuration Policy with name '$PolicyName'..." -ForegroundColor Red
    Write-Host 

}