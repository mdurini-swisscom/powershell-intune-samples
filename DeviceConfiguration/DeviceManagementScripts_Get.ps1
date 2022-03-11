
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################


 
####################################################

Function Get-DeviceManagementScripts(){

<#
.SYNOPSIS
This function is used to get device management scripts from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device management scripts
.EXAMPLE
Get-DeviceManagementScripts
Returns any device management scripts configured in Intune
Get-DeviceManagementScripts -ScriptId $ScriptId
Returns a device management script configured in Intune
.NOTES
NAME: Get-DeviceManagementScripts
#>

[cmdletbinding()]

param (

    [Parameter(Mandatory=$false)]
    $ScriptId

)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/deviceManagementScripts"
    
    try {

        if($ScriptId){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$ScriptId"

        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$expand=groupAssignments"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value

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

Write-Host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        Write-Host

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

$PSScripts = Get-DeviceManagementScripts

if($PSScripts){

    write-host "-------------------------------------------------------------------"
    Write-Host

    $PSScripts | foreach {

    $ScriptId = $_.id
    $DisplayName = $_.displayName

    Write-Host "PowerShell Script: $DisplayName..." -ForegroundColor Yellow

    $_

    write-host "Device Management Scripts - Assignments" -f Cyan

    $Assignments = $_.groupAssignments.targetGroupId
    
        if($Assignments){
    
            foreach($Group in $Assignments){
    
            (Get-AADGroup -id $Group).displayName
    
            }
    
            Write-Host
    
        }
    
        else {
    
        Write-Host "No assignments set for this policy..." -ForegroundColor Red
        Write-Host
    
        }

    $Script = Get-DeviceManagementScripts -ScriptId $ScriptId

    $ScriptContent = $Script.scriptContent

    Write-Host "Script Content:" -ForegroundColor Cyan

    [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$ScriptContent"))

    Write-Host
    write-host "-------------------------------------------------------------------"
    Write-Host

    }

}

else {

Write-Host
Write-Host "No PowerShell scripts have been added to the service..." -ForegroundColor Red
Write-Host

}
