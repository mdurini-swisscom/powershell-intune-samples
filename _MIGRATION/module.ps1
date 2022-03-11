Function Get-ApplePushNotificationCertificate(){

    <#
    .SYNOPSIS
    This function is used to get applecPushcNotificationcCertificate from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets a configured apple Push Notification Certificate
    .EXAMPLE
    Get-ApplePushNotificationCertificate
    Returns apple Push Notification Certificate configured in Intune
    .NOTES
    NAME: Get-ApplePushNotificationCertificate
    #>
    
    [cmdletbinding()]
    
    
    $graphApiVersion = "v1.0"
    $Resource = "devicemanagement/applePushNotificationCertificate"
    
        try {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
    
        }
    
        catch {
    
        $ex = $_.Exception
    
            if(($ex.message).contains("404")){
            
            Write-Host "Resource Not Configured" -ForegroundColor Red
            
            }
    
            else {
    
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            write-host
    
            }
    
        }
    
    }
Function Sync-AppleDEP(){

    <#
    .SYNOPSIS
    Sync Intune tenant to Apple DEP service
    .DESCRIPTION
    Intune automatically syncs with the Apple DEP service once every 24hrs. This function synchronises your Intune tenant with the Apple DEP service.
    .EXAMPLE
    Sync-AppleDEP
    .NOTES
    NAME: Sync-AppleDEP
    #>
    
    [cmdletbinding()]
    
    Param(
    [parameter(Mandatory=$true)]
    [string]$id
    )
    
    
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/depOnboardingSettings/$id/syncWithAppleDeviceEnrollmentProgram"
    
        try {
    
            $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            Invoke-RestMethod -Uri $SyncURI -Headers $authToken -Method Post
    
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

Function Get-DEPOnboardingSettings {

    <#
    .SYNOPSIS
    This function retrieves the DEP onboarding settings for your tenant. DEP Onboarding settings contain information such as Token ID, which is used to sync DEP and VPP
    .DESCRIPTION
    The function connects to the Graph API Interface and gets a retrieves the DEP onboarding settings.
    .EXAMPLE
    Get-DEPOnboardingSettings
    Gets all DEP Onboarding Settings for each DEP token present in the tenant
    .NOTES
    NAME: Get-DEPOnboardingSettings
    #>
    
    [cmdletbinding()]
    
    Param(
    [parameter(Mandatory=$false)]
    [string]$tokenid
    )
    
    $graphApiVersion = "beta"
    
        try {
    
            if ($tokenid){
            
            $Resource = "deviceManagement/depOnboardingSettings/$tokenid/"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
                    
            }
    
            else {
            
            $Resource = "deviceManagement/depOnboardingSettings/"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value
            
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
Function Get-DEPProfiles(){

    <#
    .SYNOPSIS
    This function is used to get a list of DEP profiles by DEP Token
    .DESCRIPTION
    The function connects to the Graph API Interface and gets a list of DEP profiles based on DEP token
    .EXAMPLE
    Get-DEPProfiles
    Gets all DEP profiles
    .NOTES
    NAME: Get-DEPProfiles
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $id
    )
    
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/depOnboardingSettings/$id/enrollmentProfiles"
    
        try {
    
            $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            Invoke-RestMethod -Uri $SyncURI -Headers $authToken -Method GET
    
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
Function Get-AADGroup(){

    <#
    .SYNOPSIS
    This function is used to get AAD Groups from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Groups registered with AAD
    .EXAMPLE
    Get-AADGroup
    Returns all users registered with Azure AD
    .NOTES
    NAME: Get-AADGroup
    #>
    
    [cmdletbinding()]
    
    param
    (
        $GroupName,
        $id,
        [switch]$Members
    )
    
    # Defining Variables
    $graphApiVersion = "v1.0"
    $Group_resource = "groups"
    # pseudo-group identifiers for all users and all devices
    [string]$AllUsers   = "acacacac-9df4-4c7d-9d50-4ef0226f57a9"
    [string]$AllDevices = "adadadad-808e-44e2-905a-0b7873a8a531"
        
        try {
    
            if($id){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
            switch ( $id ) {
                $AllUsers   { $grp = [PSCustomObject]@{ displayName = "All users"}; $grp           }
                $AllDevices { $grp = [PSCustomObject]@{ displayName = "All devices"}; $grp         }
                default     { (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value  }
                }
    
            }
            
            elseif($GroupName -eq "" -or $GroupName -eq $null){
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            
            }
    
            else {
                
                if(!$Members){
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
                
                }
                
                elseif($Members){
                
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
                
                    if($Group){
    
                    $GID = $Group.id
    
                    $Group.displayName
                    write-host
    
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"
                    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
                    }
    
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

Function Assign-ProfileToDevice(){

    <#
    .SYNOPSIS
    This function is used to assign a profile to given devices using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and assigns a profile to given devices
    .EXAMPLE
    Assign-ProfileToDevice
    Assigns a profile to given devices in Intune
    .NOTES
    NAME: Assign-ProfileToDevice
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $id,
        [Parameter(Mandatory=$true)]
        $DeviceSerialNumber,
        [Parameter(Mandatory=$true)]
        $ProfileId
    )
    
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/depOnboardingSettings/$id/enrollmentProfiles('$ProfileId')/updateDeviceProfileAssignment"
    
        try {
    
            $DevicesArray = $DeviceSerialNumber -split ","
    
            $JSON = @{ "deviceIds" = $DevicesArray } | ConvertTo-Json
    
            Test-JSON -JSON $JSON
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
            Write-Host "Success: " -f Green -NoNewline
            Write-Host "Device assigned!"
            Write-Host
    
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
function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>

        [cmdletbinding()]

        param
        (
            [Parameter(Mandatory=$true)]
            $User
        )

        $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

        $tenant = $userUpn.Host

        Write-Host "Checking for AzureAD module..."

        $AadModule = Get-Module -Name "AzureAD" -ListAvailable

        if ($AadModule -eq $null) {

            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

        }

        if ($AadModule -eq $null) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }

        # Getting path to ActiveDirectory Assemblies
        # If the module count is greater than 1 find the latest version

        if($AadModule.count -gt 1){

            $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]

            $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

                # Checking if there are multiple versions of the same module found

                if($AadModule.count -gt 1){

                $aadModule = $AadModule | Select-Object -Unique

                }

            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

        }

        else {

            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

        }

        [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

        [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

        $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

        $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

        $resourceAppIdURI = "https://graph.microsoft.com"

        $authority = "https://login.microsoftonline.com/$Tenant"

        try {

            $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

            # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
            # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

            $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

            $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

            $MethodArguments = [Type[]]@("System.String", "System.String", "System.Uri", "Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior", "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier")
            $NonAsync = $AuthContext.GetType().GetMethod("AcquireToken", $MethodArguments)
            
            if ($NonAsync -ne $null) {
                $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, [Uri]$redirectUri, [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto, $userId)
            } else {
                $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, [Uri]$redirectUri, $platformParameters, $userId).Result 
            }

            # If the accesstoken is valid then create the authentication header

            if($authResult.AccessToken){

                # Creating header for Authorization token

                $authHeader = @{
                    'Content-Type'='application/json'
                    'Authorization'="Bearer " + $authResult.AccessToken
                    'ExpiresOn'=$authResult.ExpiresOn
                    }

                return $authHeader

            }

        else {

                Write-Host
                Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
                Write-Host
                break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}

function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Tenant,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret
    )
    
        $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    
        if ($AadModule -eq $null) {
    
            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    
        }
    
        if ($AadModule -eq $null) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }
    
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    
        if($AadModule.count -gt 1){
    
            $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
    
            $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
    
                # Checking if there are multiple versions of the same module found
    
                if($AadModule.count -gt 1){
    
                $aadModule = $AadModule | select -Unique
    
                }
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
        else {
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://graph.microsoft.com"
    
    $authority = "https://login.microsoftonline.com/$Tenant"
    
        try {
    
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority, $false
    
        # turn this on for app only auth
        $ClientCred = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential" -ArgumentList $clientId, $ClientSecret
       
        # turn this on for app only auth
        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $ClientCred)
    
    
            # If the accesstoken is valid then create the authentication header
            $accesstoken = $authResult.Result.CreateAuthorizationHeader()
    
            $authHeader = @{
    
                'Authorization'=$accesstoken
            
            }
    
            return $authHeader
    
        }
    
        catch {
    
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
    
        }
    
    }

function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $User,
        $Password
    )
    
    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    
    $tenant = $userUpn.Host
    
    Write-Host "Checking for AzureAD module..."
    
        $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    
        if ($AadModule -eq $null) {
    
            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    
        }
    
        if ($AadModule -eq $null) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }
    
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    
        if($AadModule.count -gt 1){
    
            $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
    
            $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
    
                # Checking if there are multiple versions of the same module found
    
                if($AadModule.count -gt 1){
    
                $aadModule = $AadModule | select -Unique
    
                }
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
        else {
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://graph.microsoft.com"
    
    $authority = "https://login.microsoftonline.com/$Tenant"
    
        try {
    
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
    
        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    
        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    
            if($Password -eq $null){
    
                $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result
    
            }
    
            else {
    
                if(test-path "$Password"){
    
                $UserPassword = get-Content "$Password" | ConvertTo-SecureString
    
                $userCredentials = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential -ArgumentList $userUPN,$UserPassword
    
                $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $clientid, $userCredentials).Result;
    
                }
    
                else {
    
                Write-Host "Path to Password file" $Password "doesn't exist, please specify a valid path..." -ForegroundColor Red
                Write-Host "Script can't continue..." -ForegroundColor Red
                Write-Host
                break
    
                }
    
            }
    
            if($authResult.AccessToken){
    
            # Creating header for Authorization token
    
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }
    
            return $authHeader
    
            }
    
            else {
    
            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            break
    
            }
    
        }
    
        catch {
    
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
    
        }
    
    }

Function Get-AndroidEnrollmentProfile {

    <#
    .SYNOPSIS
    Gets Android Enterprise Enrollment Profile
    .DESCRIPTION
    Gets Android Enterprise Enrollment Profile
    .EXAMPLE
    Get-AndroidEnrollmentProfile
    .NOTES
    NAME: Get-AndroidEnrollmentProfile
    #>
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/androidDeviceOwnerEnrollmentProfiles"
        
        try {
            
            $now = (Get-Date -Format s)    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=tokenExpirationDateTime gt $($now)z"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
                
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

Function Get-AndroidQRCode{

    <#
    .SYNOPSIS
    Gets Android Device Owner Enrollment Profile QRCode Image
    .DESCRIPTION
    Gets Android Device Owner Enrollment Profile QRCode Image
    .EXAMPLE
    Get-AndroidQRCode
    .NOTES
    NAME: Get-AndroidQRCode
    #>
    
    [cmdletbinding()]
    
    Param(
    [parameter(Mandatory=$true)]
    [string]$Profileid
    )
    
    $graphApiVersion = "Beta"
    
        try {
                
            $Resource = "deviceManagement/androidDeviceOwnerEnrollmentProfiles/$($Profileid)?`$select=qrCodeImage"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
                        
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

Function Get-DeviceEnrollmentConfigurations(){

    <#
    .SYNOPSIS
    This function is used to get Deivce Enrollment Configurations from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets Device Enrollment Configurations
    .EXAMPLE
    Get-DeviceEnrollmentConfigurations
    Returns Device Enrollment Configurations configured in Intune
    .NOTES
    NAME: Get-DeviceEnrollmentConfigurations
    #>
        
    [cmdletbinding()]
        
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceEnrollmentConfigurations"
            
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
