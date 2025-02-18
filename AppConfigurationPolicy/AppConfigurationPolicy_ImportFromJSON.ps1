
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

Function Test-AppBundleId(){

<#
.SYNOPSIS
This function is used to test whether an app bundle ID is present in the client apps from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and checks whether the app bundle ID has been added to the client apps
.EXAMPLE
Test-AppBundleId -bundleId 
Returns the targetedMobileApp GUID for the specified app GUID in Intune
.NOTES
NAME: Test-AppBundleId
#>

param (

$bundleId

)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps?`$filter=(microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true) and (isof('microsoft.graph.iosLobApp') or isof('microsoft.graph.iosStoreApp') or isof('microsoft.graph.iosVppApp') or isof('microsoft.graph.managedIOSStoreApp') or isof('microsoft.graph.managedIOSLobApp'))"

   try {
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $mobileApps = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
             
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
    Write-Host
    break

    }

    $app = $mobileApps.value | where {$_.bundleId -eq $bundleId}
    
    If($app){
    
        return $app.id

    }
    
    Else{

        return $false

    }
       
}

####################################################

Function Test-AppPackageId(){

<#
.SYNOPSIS
This function is used to test whether an app package ID is present in the client apps from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and checks whether the app package ID has been added to the client apps
.EXAMPLE
Test-AppPackageId -packageId 
Returns the targetedMobileApp GUID for the specified app GUID in Intune
.NOTES
NAME: Test-AppPackageId
#>

param (

$packageId

)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps?`$filter=(isof('microsoft.graph.androidForWorkApp') or microsoft.graph.androidManagedStoreApp/supportsOemConfig eq false)"

   try {
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $mobileApps = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        
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
    Write-Host
    break

    }

    $app = $mobileApps.value | where {$_.packageId -eq $packageId}
    
    If($app){
    
        return $app.id

    }
    
    Else{

        return $false

    }

}

####################################################

Function Add-ManagedAppAppConfigPolicy(){

<#
.SYNOPSIS
This function is used to add an app configuration policy for managed apps using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds an app configuration policy for managed apps
.EXAMPLE
Add-ManagedAppAppConfiguPolicy -JSON $JSON
.NOTES
NAME: Add-ManagedAppAppConfigPolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/targetedManagedAppConfigurations"
    
    try {

        if($JSON -eq "" -or $JSON -eq $null){

        Write-Host "No JSON specified, please specify valid JSON for the App Configuration Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

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
    Write-Host
    break

    }

}

####################################################

Function Add-ManagedDeviceAppConfigPolicy(){

<#
.SYNOPSIS
This function is used to add an app configuration policy for managed devices using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds an app configuration policy for managed devices
.EXAMPLE
Add-ManagedDeviceAppConfiguPolicy -JSON $JSON
.NOTES
NAME: Add-ManagedDeviceAppConfigPolicy
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileAppConfigurations"
    
    try {

        if($JSON -eq "" -or $JSON -eq $null){

        Write-Host "No JSON specified, please specify valid JSON for the App Configuration Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

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
    Write-Host
    break

    }

}

####################################################

#region Authentication

Write-Host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        Write-Host

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

$ImportPath = Read-Host -Prompt "Please specify a path to a JSON file to import data from e.g. C:\IntuneOutput\Policies\policy.json"

# Replacing quotes for Test-Path
$ImportPath = $ImportPath.replace('"','')

if(!(Test-Path "$ImportPath")){

Write-Host "Import Path for JSON file doesn't exist..." -ForegroundColor Red
Write-Host "Script can't continue..." -ForegroundColor Red
Write-Host
break

}

$JSON_Data = gc "$ImportPath"

# Excluding entries that are not required - id,createdDateTime,lastModifiedDateTime,version
$JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,isAssigned,roleScopeTagIds

$DisplayName = $JSON_Convert.displayName

Write-Host
Write-Host "App Configuration Policy '$DisplayName' Found..." -ForegroundColor Yellow


# Check if the JSON is for Managed Apps or Managed Devices
If(($JSON_Convert.'@odata.type' -eq "#microsoft.graph.iosMobileAppConfiguration") -or ($JSON_Convert.'@odata.type' -eq "#microsoft.graph.androidManagedStoreAppConfiguration")){

    Write-Host "App Configuration JSON is for Managed Devices" -ForegroundColor Yellow

    If($JSON_Convert.'@odata.type' -eq "#microsoft.graph.iosMobileAppConfiguration"){

        # Check if the client app is present 
        $targetedMobileApp = Test-AppBundleId -bundleId $JSON_Convert.bundleId
           
        If($targetedMobileApp){

            Write-Host
            Write-Host "Targeted app $($JSON_Convert.bundleId) has already been added from the App Store" -ForegroundColor Yellow
            Write-Host "The App Configuration Policy will be created" -ForegroundColor Yellow
            Write-Host

            # Update the targetedMobileApps GUID if required
            If(!($targetedMobileApp -eq $JSON_Convert.targetedMobileApps)){

                $JSON_Convert.targetedMobileApps.SetValue($targetedMobileApp,0)

            }

            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
            $JSON_Output
            Write-Host
            Write-Host "Adding App Configuration Policy '$DisplayName'" -ForegroundColor Yellow
            Add-ManagedDeviceAppConfigPolicy -JSON $JSON_Output

        }

        Else
        {

            Write-Host
            Write-Host "Targeted app bundle id '$($JSON_Convert.bundleId)' has not been added from the App Store" -ForegroundColor Red
            Write-Host "The App Configuration Policy can't be created" -ForegroundColor Red

        }


    }

    ElseIf($JSON_Convert.'@odata.type' -eq "#microsoft.graph.androidManagedStoreAppConfiguration"){

        # Check if the client app is present 
        $targetedMobileApp = Test-AppPackageId -packageId $JSON_Convert.packageId
        
        If($targetedMobileApp){

            Write-Host
            Write-Host "Targeted app $($JSON_Convert.packageId) has already been added from Managed Google Play" -ForegroundColor Yellow
            Write-Host "The App Configuration Policy will be created" -ForegroundColor Yellow
            Write-Host
            
            # Update the targetedMobileApps GUID if required           
            If(!($targetedMobileApp -eq $JSON_Convert.targetedMobileApps)){
               
                $JSON_Convert.targetedMobileApps.SetValue($targetedMobileApp,0)

            }

            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
            $JSON_Output
            Write-Host   
            Write-Host "Adding App Configuration Policy '$DisplayName'" -ForegroundColor Yellow                                                      
            Add-ManagedDeviceAppConfigPolicy -JSON $JSON_Output

        }

        Else
        {

            Write-Host
            Write-Host "Targeted app package id '$($JSON_Convert.packageId)' has not been added from Managed Google Play" -ForegroundColor Red
            Write-Host "The App Configuration Policy can't be created" -ForegroundColor Red

        }
    
    }

}

Else
{

    Write-Host "App Configuration JSON is for Managed Apps" -ForegroundColor Yellow
    $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
    $JSON_Output
    Write-Host
    Write-Host "Adding App Configuration Policy '$DisplayName'" -ForegroundColor Yellow
    Add-ManagedAppAppConfigPolicy -JSON $JSON_Output   

}
 




