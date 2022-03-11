
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

$graphApiVersion = "Beta"
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

Function Add-RBACRole(){

<#
.SYNOPSIS
This function is used to add an RBAC Role Definitions from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds an RBAC Role Definitions
.EXAMPLE
Add-RBACRole -JSON $JSON
.NOTES
NAME: Add-RBACRole
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions"
    
    try {

        if(!$JSON){

        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }

        Test-JSON -JSON $JSON
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $Json -ContentType "application/json"
    
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
NAME: Test-JSON
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

Write-Host "Please specify which Intune Role you want to duplicate:" -ForegroundColor Yellow
Write-Host

$RBAC_Roles = (Get-RBACRole | Where-Object { $_.isBuiltInRoleDefinition -eq $true } | Select-Object displayName).displayName

$menu = @{}

for ($i=1;$i -le $RBAC_Roles.count; $i++) 
{ Write-Host "$i. $($RBAC_Roles[$i-1])" 
$menu.Add($i,($RBAC_Roles[$i-1]))}

Write-Host
[int]$ans = Read-Host 'Enter Intune Role to Duplicate (Numerical value)'
$selection = $menu.Item($ans)

    if($selection){

    Write-Host
    Write-Host $selection -f Cyan
    Write-Host

    $RBAC_Role = (Get-RBACRole | Where-Object { $_.displayName -eq "$Selection" -and $_.isBuiltInRoleDefinition -eq $true })
    $RBAC_Actions = $RBAC_Role.permissions.actions | ConvertTo-Json

    $RBAC_DN = Read-Host "Please specify a displayName for the duplicated Intune Role"

        if($RBAC_DN -eq ""){

            Write-Host "Intune Role DisplayName can't be null, please specify a valid DisplayName..." -ForegroundColor Red
            Write-Host
            break

        }

        if(Get-RBACRole | Where-Object { $_.displayName -eq "$RBAC_DN"}){

            Write-Host "A Custom Intune role with the name '$RBAC_DN' already exists..." -ForegroundColor Red
            Write-Host
            break

        }

$JSON = @"
        {
        "@odata.type": "#microsoft.graph.roleDefinition",
        "displayName": "$RBAC_DN",
        "description": "$RBAC_DN",
        "permissions": [
                {   
                "actions": $RBAC_Actions
                }
            
            ],
            "isBuiltInRoleDefinition": false  
        }
"@

        Write-Host
        
        $JSON
        
        Write-Host
        Write-Host "Duplicating Intune Role and Adding to the Intune Service..." -ForegroundColor Yellow

        Add-RBACRole -JSON $JSON

    }

    else {

    Write-Host
    Write-Host "Intune Role specified is invalid..." -f Red
    Write-Host "Please specify a valid Intune Role..." -f Red
    Write-Host
    break

    }

Write-Host