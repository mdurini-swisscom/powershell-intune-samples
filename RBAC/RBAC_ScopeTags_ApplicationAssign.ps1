﻿<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Get-RBACScopeTag(){

<#
.SYNOPSIS
This function is used to get scope tags using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets scope tags
.EXAMPLE
Get-RBACScopeTag -DisplayName "Test"
Gets a scope tag with display Name 'Test'
.NOTES
NAME: Get-RBACScopeTag
#>

[cmdletbinding()]
    
param
(
    [Parameter(Mandatory=$false)]
    $DisplayName
)

# Defining Variables
$graphApiVersion = "beta"
$Resource = "deviceManagement/roleScopeTags"

    try {

        if($DisplayName){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=displayName eq '$DisplayName'"
            $Result = (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken).Value

        }

        else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            $Result = (Invoke-RestMethod -Uri $uri -Method Get -Headers $authToken).Value

        }

    return $Result

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
    throw
    }

}

####################################################

Function Get-IntuneApplication(){

<#
.SYNOPSIS
This function is used to get applications from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any applications added
.EXAMPLE
Get-IntuneApplication
Returns any applications configured in Intune
.NOTES
NAME: Get-IntuneApplication
#>

[cmdletbinding()]

param
(
    $displayName,
    $id
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps"
    
    try {
        
        if($displayName){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=displayName eq '$displayName'"
            (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value

        }
        
        elseif($id){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$id"
            (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)

        }

        else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value | ? { (!($_.'@odata.type').Contains("managed")) }
        
        }
    }
    
    catch {

    $ex = $_.Exception
    Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red
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

Function Update-IntuneApplication(){

<#
.SYNOPSIS
This function is used to update an Intune Application using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and updates an Intune Application
.EXAMPLE
Update-IntuneApplication -id $id -Type "#microsoft.graph.WebApp" -ScopeTags "1,2,3"
Updates an Intune Application with selected scope tags
.NOTES
NAME: Update-IntuneApplication
#>

[cmdletbinding()]

param
(
    $id,
    $Type,
    $ScopeTags
)

$graphApiVersion = "beta"
$Resource = "deviceAppManagement/mobileApps/$id"

    try {

        if(($Type -eq "#microsoft.graph.microsoftStoreForBusinessApp") -or ($Type -eq "#microsoft.graph.iosVppApp")){

            Write-Warning "Scope Tags aren't available on '$Type' application Type..."

        }
        
        else {
        
        if($ScopeTags -eq "" -or $ScopeTags -eq $null){

$JSON = @"

{
  "@odata.type": "$Type",
  "roleScopeTagIds": []
}

"@
        }

        else {

            $object = New-Object –TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value "$Type"
            $object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
            $JSON = $object | ConvertTo-Json

        }

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"

        Start-Sleep -Milliseconds 100

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

#region Authentication

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

            $Global:User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    Write-Host
    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################

#region ScopeTags Menu

Write-Host

$ScopeTags = (Get-RBACScopeTag).displayName | Sort-Object

if($ScopeTags){

Write-Host "Please specify Scope Tag you want to add to all users / devices in AAD Group:" -ForegroundColor Yellow

$menu = @{}

for ($i=1;$i -le $ScopeTags.count; $i++) 
{ Write-Host "$i. $($ScopeTags[$i-1])" 
$menu.Add($i,($ScopeTags[$i-1]))}

Write-Host
$ans = Read-Host 'Enter Scope Tag id (Numerical value)'

if($ans -eq "" -or $ans -eq $null){

    Write-Host "Scope Tag can't be null, please specify a valid Scope Tag..." -ForegroundColor Red
    Write-Host
    break

}

elseif(($ans -match "^[\d\.]+$") -eq $true){

$selection = $menu.Item([int]$ans)

    if($selection){

        $ScopeTagId = (Get-RBACScopeTag | Where-Object { $_.displayName -eq "$selection" }).id

    }

    else {

        Write-Host "Scope Tag selection invalid, please specify a valid Scope Tag..." -ForegroundColor Red
        Write-Host
        break

    }

}

else {

    Write-Host "Scope Tag not an integer, please specify a valid scope tag..." -ForegroundColor Red
    Write-Host
    break

}

Write-Host

}

else {

    Write-Host "No Scope Tags created, script can't continue..." -ForegroundColor Red
    Write-Host
    break

}

#endregion

####################################################

$displayName = "Bing Web App"

$Application = Get-IntuneApplication -displayName "$displayName"

if(@($Application).count -eq 1){

    $IA = Get-IntuneApplication -id $Application.id

    $ADN = $Application.displayName
    $AT = $Application.'@odata.type'

    Write-Host "Intune Application '$ADN' with type '$AT' found..."

        if($IA.roleScopeTagIds){

            if(!($IA.roleScopeTagIds).contains("$ScopeTagId")){

                $ST = @($IA.roleScopeTagIds) + @("$ScopeTagId")

                $Result = Update-IntuneApplication -id $IA.id -Type $IA.'@odata.type' -ScopeTags $ST

                if($Result -eq ""){

                    Write-Host "Intune Application '$ADN' patched with ScopeTag '$selection'..." -ForegroundColor Green
                            
                }

            }

            else {

                Write-Host "Scope Tag '$selection' already assigned to '$ADN'..." -ForegroundColor Magenta

            }

        }

        else {

            $ST = @("$ScopeTagId")

            $Result = Update-IntuneApplication -id $IA.id -Type $IA.'@odata.type' -ScopeTags $ST

            if($Result -eq ""){

                Write-Host "Intune Application '$ADN' patched with ScopeTag '$selection'..." -ForegroundColor Green

            }

        }

}

elseif(@($Application).count -gt 1){

    Write-Host "More than one Intune Application found with name '$displayName'..." -ForegroundColor Red

}

else {

    Write-Host "No Intune Application found with '$displayName'..." -ForegroundColor Red

}

Write-Host

####################################################

