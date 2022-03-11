<#
 
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

function Get-AndroidManagedStoreAccount {

<#
.SYNOPSIS
This function is used to query the Managed Google Play configuration via the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and returns the Managed Google Play configuration 
.EXAMPLE
Get-AndroidManagedStoreAccount 
Returns the Managed Google Play configuration from Intune 
.NOTES
NAME: Get-AndroidManagedStoreAccount
#>

    
$graphApiVersion = "beta"
$Resource = "deviceManagement/androidManagedStoreAccountEnterpriseSettings"
    
    try {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        Invoke-RestMethod -Method Get -Uri $uri -Headers $authToken  
        
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

function Sync-AndroidManagedStoreAccount {

<#
.SYNOPSIS
This function is used to initiate an app sync for Managed Google Play via the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and initiates a Managed Google Play app sync
.EXAMPLE
Sync-AndroidManagedStoreAccount
Initiates a Managed Google Play Sync in Intune
.NOTES
NAME: Sync-AndroidManagedStoreAccount
#>

    
$graphApiVersion = "beta"
$Resource = "deviceManagement/androidManagedStoreAccountEnterpriseSettings/syncApps"
    
    try {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        Invoke-RestMethod -Method Post -Uri $uri -Headers $authToken  
        
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

if((Get-AndroidManagedStoreAccount).bindStatus -ne "notBound"){

    Write-Host "Found Managed Google Play Configuration. Performing Sync..." -ForegroundColor Yellow
    
    $ManagedPlaySync = Sync-AndroidManagedStoreAccount
    
    if($ManagedPlaySync -ne $null){

        Write-Host "Starting sync with managed Google Play, Sync will take some time" -ForegroundColor Green
    
    }
    
    else {
        
        $ManagedPlaySync
        Write-Host "Managed Google Play sync was not successful" -ForegroundColor Red
        break
    
    }

}
    
else {

    Write-Host "No Managed Google Play configuration found for this tenant" -ForegroundColor Cyan

}

Write-Host