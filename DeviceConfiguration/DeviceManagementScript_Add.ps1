<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################


####################################################

Function Add-DeviceManagementScript() {
    <#
.SYNOPSIS
This function is used to add a device management script using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device management script
.EXAMPLE
Add-DeviceManagementScript -File "path to powershell-script file"
Adds a device management script from a File in Intune
Add-DeviceManagementScript -File "URL to powershell-script file" -URL
Adds a device management script from a URL in Intune
.NOTES
NAME: Add-DeviceManagementScript
#>
    [cmdletbinding()]
    Param (
        # Path or URL to Powershell-script to add to Intune
        [Parameter(Mandatory = $true)]
        [string]$File,
        # PowerShell description in Intune
        [Parameter(Mandatory = $false)]
        [string]$Description,
        # Set to true if it is a URL
        [Parameter(Mandatory = $false)]
        [switch][bool]$URL = $false
    )
    if ($URL -eq $true) {
        $FileName = $File -split "/"
        $FileName = $FileName[-1]
        $OutFile = "$env:TEMP\$FileName"
        try {
            Invoke-WebRequest -Uri $File -UseBasicParsing -OutFile $OutFile
        }
        catch {
            Write-Host "Could not download file from URL: $File" -ForegroundColor Red
            break
        }
        $File = $OutFile
        if (!(Test-Path $File)) {
            Write-Host "$File could not be located." -ForegroundColor Red
            break
        }
    }
    elseif ($URL -eq $false) {
        if (!(Test-Path $File)) {
            Write-Host "$File could not be located." -ForegroundColor Red
            break
        }
        $FileName = Get-Item $File | Select-Object -ExpandProperty Name
    }
    $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$File"));

    if ($URL -eq $true) {
        Remove-Item $File -Force
    }

    $JSON = @"
{
    "@odata.type": "#microsoft.graph.deviceManagementScript",
    "displayName": "$FileName",
    "description": "$Description",
    "runSchedule": {
    "@odata.type": "microsoft.graph.runSchedule"
},
    "scriptContent": "$B64File",
    "runAsAccount": "system",
    "enforceSignatureCheck": "false",
    "fileName": "$FileName"
}
"@

    $graphApiVersion = "Beta"
    $DMS_resource = "deviceManagement/deviceManagementScripts"
    Write-Verbose "Resource: $DMS_resource"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$DMS_resource"
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

#region Authentication

write-host

# Checking if authToken exists before running authentication
if ($global:authToken) {

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if ($TokenExpires -le 0) {

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

        # Defining User Principal Name if not present

        if ($User -eq $null -or $User -eq "") {

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

        }

        $global:authToken = Get-AuthToken -User $User

    }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if ($User -eq $null -or $User -eq "") {

        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host

    }

    # Getting the authorization token
    $global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################


Add-DeviceManagementScript -File "C:\Scripts\test-script.ps1" -Description "Test script"

Add-DeviceManagementScript -File "https://pathtourl/test-script.ps1" -URL -Description "Test script"