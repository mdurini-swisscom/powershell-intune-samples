
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################


    
####################################################

Function Get-AuditCategories(){
    
<#
.SYNOPSIS
This function is used to get all audit categories from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets all audit categories
.EXAMPLE
Get-AuditCategories
Returns all audit categories configured in Intune
.NOTES
NAME: Get-AuditCategories
#>
    
[cmdletbinding()]
    
param
(
    $Name
)
    
$graphApiVersion = "Beta"
$Resource = "deviceManagement/auditEvents/getAuditCategories"
    
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

Function Get-AuditEvents(){
    
<#
.SYNOPSIS
This function is used to get all audit events from a specific category using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets audit events from a specific audit category
.EXAMPLE
Get-AuditEvents -category "Application"
Returns audit events from the category "Application" configured in Intune
Get-AuditEvents -category "Application" -days 7
Returns audit events from the category "Application" in the past 7 days configured in Intune
.NOTES
NAME: Get-AuditEvents
#>
    
[cmdletbinding()]
    
param
(
    [Parameter(Mandatory=$true)]
    $Category,
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,30)]
    [Int]$days
)
    
$graphApiVersion = "Beta"
$Resource = "deviceManagement/auditEvents"

if($days){ $days }
else { $days = 30 }

$daysago = "{0:s}" -f (get-date).AddDays(-$days) + "Z"
    
    try {
    
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=category eq '$Category' and activityDateTime gt $daysago"
    Write-Verbose $uri
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

$AuditCategories = Get-AuditCategories

Write-Host "Intune Audit Categories:" -ForegroundColor Yellow

$menu = @{}

for ($i=1;$i -le $AuditCategories.count; $i++) 
{ Write-Host "$i. $($AuditCategories[$i-1])" 
$menu.Add($i,($AuditCategories[$i-1]))}

Write-Host
[int]$ans = Read-Host 'Enter Category Name (Numerical value)'
$selection = $menu.Item($ans)

if($selection){

$selection

Write-Host
write-host "-------------------------------------------------------------------"
Write-Host

$Events = Get-AuditEvents -Category $selection

    if($Events){

        foreach($Event in ($Events | Sort-Object -Property activityDateTime )){

        Write-Host $Event.displayName -f Yellow
        Write-Host "Component Name:" $Event.componentName
        Write-Host "Activity Type:" $Event.activityType
        Write-Host "Activity Date Time:" $Event.activityDateTime
        Write-Host "Application:" $Event.actor.applicationDisplayName

            if($Event.activityResult -eq "Success"){

            Write-Host "Activity Result:" $Event.activityResult -ForegroundColor Green

            }

            else {

            Write-Host "Activity Result:" $Event.activityResult -ForegroundColor Red

            }

        Write-Host
        Write-Host "User Information" -ForegroundColor Cyan
        $Event.actor

        Write-Host "Resource Information" -ForegroundColor Cyan
        $Event.resources

        Write-Host "-------------------------------------------------------------------"
        Write-Host

        }

    }

    else {

    Write-Host "No audit events found for '$selection' in the past month..." -ForegroundColor Cyan
    Write-Host
    Write-Host "-------------------------------------------------------------------"
    Write-Host

    }

}