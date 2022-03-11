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

$graphApiVersion = "v1.0"
$Resource = "deviceManagement/roleDefinitions"
    
    try {
    
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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

$ExportPath = Read-Host -Prompt "Please specify a path to export RBAC Intune Roles to e.g. C:\IntuneOutput"

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

$RBAC_Roles = (Get-RBACRole | Where-Object { $_.isBuiltIn -eq $false })

foreach($RBAC_Role in $RBAC_Roles){

    $RBAC_DisplayName = $RBAC_Role.displayName
    $RBAC_Description = $RBAC_Role.description

    $FileName_JSON = "$RBAC_DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json"

    $RBAC_Actions = $RBAC_Role.RolePermissions.resourceActions.allowedResourceActions | ConvertTo-Json

$JSON = @"
{
    "@odata.type": "#microsoft.graph.deviceAndAppManagementRoleDefinition",
    "displayName": "$RBAC_DisplayName",
    "description": "$RBAC_Description",
    "rolePermissions": [
        {
        "resourceActions": [
        {
        "allowedResourceActions": $RBAC_Actions,
        "notAllowedResourceActions": []
        }
        ]
        }
    ],
    "isBuiltIn": false  
}
"@

    $JSON | Set-Content -LiteralPath "$ExportPath\$FileName_JSON"
    write-host "JSON created in $ExportPath\$FileName_JSON..." -f cyan
    Write-Host


}