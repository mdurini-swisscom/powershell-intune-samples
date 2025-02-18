
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



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



####################################################

Function Add-TermsAndConditions(){

<#
.SYNOPSIS
This function is used to add Terms and Conditions using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds Terms and Conditions Statement
.EXAMPLE
Add-TermsAndConditions -JSON $JSON
Adds Terms and Conditions into Intune
.NOTES
NAME: Add-TermsAndConditions
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/termsAndConditions"
    
    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

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

Function Assign-TermsAndConditions(){

<#
.SYNOPSIS
This function is used to assign Terms and Conditions from Intune to a Group using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and assigns terms and conditions to a group
.EXAMPLE
Assign-TermsAndConditions -id $id -TargetGroupId
.NOTES
NAME: Assign-TermsAndConditions
#>   

[cmdletbinding()]

param
(
    $id,
    $TargetGroupId
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/termsAndConditions/$id/groupAssignments"

    try {

        if(!$id){

        Write-Host "No Terms and Conditions ID was passed to the function, specify a valid terms and conditions ID" -ForegroundColor Red
        Write-Host
        break

        }

        if(!$TargetGroupId){

        write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        Write-Host
        break

        }

        else {

$JSON = @"

{
    "targetGroupId":"$TargetGroupId"
}

"@

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json" 

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

$JSON = @"

{
    "@odata.type": "#microsoft.graph.termsAndConditions",
    "displayName":"Customer Terms and Conditions",
    "title":"Terms and Conditions",
    "description":"Desription of the terms and conditions",
    "bodyText":"This is where the body text for the terms and conditions is set\n\nTest Web Address - https://www.bing.com\n\nCustomer IT Department",
    "acceptanceStatement":"Acceptance statement text goes here",
    "version":1
}

"@

####################################################

# Setting AAD Group

$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where terms and conditions will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id

    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
    Write-Host
    exit

    }

####################################################

Write-Host
Write-Host "Adding Terms and Conditions from JSON..." -ForegroundColor Cyan
Write-Host "Creating Terms and Conditions via Graph"
$CreateResult = Add-TermsAndConditions -JSON $JSON
write-host "Terms and Conditions created with id" $CreateResult.id

Write-Host

write-host "Assigning Terms and Conditions to AAD Group '$AADGroup'" -f Yellow
$Assign_Policy = Assign-TermsAndConditions -id $CreateResult.id -TargetGroupId $TargetGroupId
Write-Host "Assigned '$AADGroup' to $($CreateResult.displayName)/$($CreateResult.id)"
Write-Host
