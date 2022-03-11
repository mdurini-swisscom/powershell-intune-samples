
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-RBACRole(){

<#
.SYNOPSIS
This function is used to get RBAC Role Definitions from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any RBAC Role Definitions
.EXAMPLE
Get-RBACRole
Returns any RBAC Role Definitions configured in Intune
.NOTES
NAME: Get-RBACRole
#>

[cmdletbinding()]

param
(
    $Name
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") -and $_.isBuiltInRoleDefinition -eq $false }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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

Function Remove-RBACRole(){

<#
.SYNOPSIS
This function is used to delete an RBAC Role Definition from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and deletes an RBAC Role Definition
.EXAMPLE
Remove-RBACRole -roleDefinitionId $roleDefinitionId
Returns any RBAC Role Definitions configured in Intune
.NOTES
NAME: Remove-RBACRole
#>

[cmdletbinding()]

param
(
    $roleDefinitionId
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions/$roleDefinitionId"

    try {

        if($roleDefinitionId -eq "" -or $roleDefinitionId -eq $null){

        Write-Host "roleDefinitionId hasn't been passed as a paramater to the function..." -ForegroundColor Red
        write-host "Please specify a valid roleDefinitionId..." -ForegroundColor Red
        break

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete

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

$RBAC_Role = Get-RBACRole -Name "Graph"

    if($RBAC_Role){

        if(@($RBAC_Role).count -gt 1){

        Write-Host "More than one RBAC Intune Role has been found, please specify a single Intune Role..." -ForegroundColor Red
        Write-Host

        }

        elseif(@($RBAC_Role).count -eq 1){

        Write-Host "Removing RBAC Intune Role" $RBAC_Role.displayName -ForegroundColor Cyan
        Remove-RBACRole -roleDefinitionId $RBAC_Role.id

        }



    }

    else {

    Write-Host "RBAC Intune Role doesn't exist..." -ForegroundColor Yellow
    Write-Host

    }
