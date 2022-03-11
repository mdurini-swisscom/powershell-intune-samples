
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Add-CorporateDeviceIdentifiers(){

<#
.SYNOPSIS
This function is used to add a Corporate Device Identifier from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a Corporate Device Identifier
.EXAMPLE
Add-CorporateDeviceIdentifiers -IdentifierType imei -OverwriteImportedDeviceIdentities false -Identifier "12345678901234" -Description "Device Information"
Adds a Corporate Device Identifier to Intune
.NOTES
NAME: Add-CorporateDeviceIdentifiers
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [ValidateSet("imei","serialNumber")]
    $IdentifierType,
    [Parameter(Mandatory=$true)]
    [ValidateSet("false","true")]
    $OverwriteImportedDeviceIdentities,
    [Parameter(Mandatory=$true)]
    $Identifier,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Description
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/importedDeviceIdentities/importDeviceIdentityList"

    try {

$JSON = @"

{
"overwriteImportedDeviceIdentities": $OverwriteImportedDeviceIdentities,
"importedDeviceIdentities": [ { 
"importedDeviceIdentifier": "$Identifier",
"importedDeviceIdentityType": "$IdentifierType",
"description": "$Description"}
]
}

"@

        if($IdentifierType -eq "imei"){

            if(($Identifier -match "^[0-9]+$") -and ($Identifier.length -ge 15)){

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken).value

            }

            elseif($Identifier -notmatch "^[0-9]+$" -or ($Identifier.length -lt 15)) {

                Write-Host "Invalid Device Identifier '$Identifier' parameter found for $IdentifierType Identity Type..." -ForegroundColor Red

            }

        }

        if($IdentifierType -eq "serialNumber"){

            if(($Identifier -match "^[a-zA-Z0-9]+$") -and (@($Description).length -le 128)){

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken).value

            }

            elseif($Identifier -notmatch "^[a-zA-Z0-9]+$"){

                Write-Host "Invalid Device Identifier '$Identifier' parameter found for $IdentifierType Identity Type..." -ForegroundColor Red

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
    $line = $_.InvocationInfo.ScriptLineNumber
    $msg = $ex.message
    $ErrorMessage += "$responseBody`n"
    $ErrorMessage += "Exception: $msg on line $line"
    Write-Error $ErrorMessage
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

$Status = Add-CorporateDeviceIdentifiers -IdentifierType imei -OverwriteImportedDeviceIdentities false -Identifier "123456789012345" -Description "Test Device"

if($Status.status -eq $true) {

    Write-Host "Device" $status.importedDeviceIdentifier "added to the Intune Service..." -ForegroundColor Green
    $Status

}

elseif($Status.status -eq $false) {

    Write-Host "Device" $status.importedDeviceIdentifier "import failed, the device identifier could have already been added to the service..." -ForegroundColor Red

}

Write-Host