<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-DirectoryRoles(){

<#
.SYNOPSIS
This function is used to get Directory Roles from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any Directory Role registered
.EXAMPLE
Get-DirectoryRoles
Returns all Directory Roles registered
.NOTES
NAME: Get-DirectoryRoles
#>

[cmdletbinding()]

param
(
    $RoleId,
    [ValidateSet("members")]
    [string]
    $Property
)

# Defining Variables
$graphApiVersion = "v1.0"
$Resource = "directoryRoles"
    
    try {
        
        if($RoleId -eq "" -or $RoleId -eq $null){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        
        }

        else {
            
            if($Property -eq "" -or $Property -eq $null){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$RoleId"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

            }

            else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$RoleId/$Property"
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


Write-Host "Please specify which Directory Role you want to query for User membership:" -ForegroundColor Yellow
Write-Host

$Roles = (Get-DirectoryRoles | Select-Object displayName).displayName | Sort-Object

$menu = @{}

for ($i=1;$i -le $Roles.count; $i++) 
{ Write-Host "$i. $($Roles[$i-1])" 
$menu.Add($i,($Roles[$i-1]))}

Write-Host

[int]$ans = Read-Host 'Enter Directory Role to query (Numerical value)'

$selection = $menu.Item($ans)

    if($selection){

    Write-Host
    Write-Host $selection -f Cyan

    $Directory_Role = (Get-DirectoryRoles | Where-Object { $_.displayName -eq "$Selection" })

    $Members = Get-DirectoryRoles -RoleId $Directory_Role.id -Property members

        if($Members){

            $Members | ForEach-Object { $_.displayName + " - " + $_.userPrincipalName }

        }

        else {

            Write-Host "No Users assigned to '$selection' Directory Role..." -ForegroundColor Red

        }

    }
        
    else {

        Write-Host
        Write-Host "Directory Role specified is invalid..." -ForegroundColor Red
        Write-Host "Please specify a valid Directory Role..." -ForegroundColor Red
        Write-Host
        break

    }

Write-Host