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


####################################################



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

#region DEP Tokens

$tokens = (Get-DEPOnboardingSettings)

if($tokens){

$tokencount = @($tokens).count

Write-Host "DEP tokens found: $tokencount"
Write-Host

    if ($tokencount -gt 1){

    write-host "Listing DEP tokens..." -ForegroundColor Yellow
    Write-Host
    $DEP_Tokens = $tokens.tokenName | Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $DEP_Tokens.count; $i++) 
    { Write-Host "$i. $($DEP_Tokens[$i-1])" 
    $menu.Add($i,($DEP_Tokens[$i-1]))}

    Write-Host
    [int]$ans = Read-Host 'Select the token you wish you to use (numerical value)'
    $selection = $menu.Item($ans)
    Write-Host

        if ($selection){

        $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$Selection" }

        $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id
        $id = $SelectedTokenId

        }

    }

    elseif ($tokencount -eq 1) {

        $id = (Get-DEPOnboardingSettings).id
    
    }

}

else {
    
    Write-Warning "No DEP tokens found!"
    Write-Host
    break

}

#endregion 

####################################################

$DeviceSerialNumber = Read-Host "Please enter device serial number"

# If variable contains spaces, remove them
$DeviceSerialNumber = $DeviceSerialNumber.replace(" ","")

if(!($DeviceSerialNumber)){
    
    Write-Host "Error: No serial number entered!" -ForegroundColor Red
    Write-Host
    break
    
}

$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$($id)/importedAppleDeviceIdentities?`$filter=discoverySource eq 'deviceEnrollmentProgram' and contains(serialNumber,'$DeviceSerialNumber')"

$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
$SearchResult = (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value

if (!($SearchResult)){

    Write-warning "Can't find device $DeviceSerialNumber."
    Write-Host
    break

}

####################################################

$Profiles = (Get-DEPProfiles -id $id).value

if($Profiles){
                
Write-Host
Write-Host "Listing DEP Profiles..." -ForegroundColor Yellow
Write-Host

$enrollmentProfiles = $Profiles.displayname | Sort-Object -Unique

$menu = @{}

for ($i=1;$i -le $enrollmentProfiles.count; $i++) 
{ Write-Host "$i. $($enrollmentProfiles[$i-1])" 
$menu.Add($i,($enrollmentProfiles[$i-1]))}

Write-Host
$ans = Read-Host 'Select the profile you wish to assign (numerical value)'

    # Checking if read-host of DEP Profile is an integer
    if(($ans -match "^[\d\.]+$") -eq $true){

        $selection = $menu.Item([int]$ans)

    }

    if ($selection){
   
        $SelectedProfile = $Profiles | Where-Object { $_.DisplayName -eq "$Selection" }
        $SelectedProfileId = $SelectedProfile | Select-Object -ExpandProperty id
        $ProfileID = $SelectedProfileId

    }

    else {

        Write-Host
        Write-Warning "DEP Profile selection invalid. Exiting..."
        Write-Host
        break

    }

}

else {
    
    Write-Host
    Write-Warning "No DEP profiles found!"
    break

}

####################################################

Assign-ProfileToDevice -id $id -DeviceSerialNumber $DeviceSerialNumber -ProfileId $ProfileID