<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################



####################################################

Function Get-iOSProvisioningProfile{

<#
.SYNOPSIS
This function is used to get iOS Provisioning Profile uploaded to Intune.
.DESCRIPTION
The function connects to the Graph API Interface and gets an iOS App Provisioning Profile.
.EXAMPLE
Get-iOSProvisioningProfile
Gets all iOS Provisioning Profiles
.NOTES
NAME: Get-iOSProvisioningProfile
#>

[cmdletbinding()]

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/iosLobAppProvisioningConfigurations?`$expand=assignments"
    
    try {
                
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value

            
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

write-host
write-host "-------------------------------------------------------------------"
Write-Host
write-host "Analysing iOS App Provisioning Profiles..." -ForegroundColor Yellow
Write-Host
write-host "-------------------------------------------------------------------"
write-host
$Profiles = (Get-iOSProvisioningProfile)
$Days = 30
$CSV = @()
$CSV += "iOSAppProvisioningProfileName,GroupAssignedName,ExpiryDate"
$GroupsOutput = @()

    foreach ($Profile in $Profiles) {
    
        $Payload = $Profile.payload
        $payloadFileName = $Profile.payloadFileName
        $PayloadRaw = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Payload))
        $Exp = ($PayloadRaw | C:\windows\System32\findstr.exe /i "date").trim()[3]
        [datetime]$ProfileExpirationDate = $Exp.TrimStart('<date>').trimend('</date>')
        $displayName = $Profile.displayName
        $GroupID = ($Profile.assignments.target.groupId)
        $CurrentTime = [System.DateTimeOffset]::Now
        $TimeDifference = ($CurrentTime - $ProfileExpirationDate)
        $TotalDays = ($TimeDifference.Days)

        write-host "iOS App Provisioning Profile Name: $($displayName)"
            
            
                if ($GroupID) {
               
                    foreach ($id in $GroupID) {
                
                            $GroupName = (Get-AADGroup -id $id).DisplayName
                            write-host "Group assigned: $($GroupName)"
                            $CSV += "$($displayName),$($GroupName),$($ProfileExpirationDate)"

                        }

                }

                else {
                
                write-host "Group assigned: " -NoNewline 
                Write-Host "Unassigned"
                $CSV += "$($displayName),,$($ProfileExpirationDate)"
                
                }
            
            if ($TotalDays -gt "0") {
           
                Write-Host "iOS App Provisioning Profile Expiration Date: " -NoNewline
                write-host "$($ProfileExpirationDate)" -ForegroundColor Red

            }

            elseif ($TotalDays -gt "-30") {
            
                    Write-Host "iOS App Provisioning Profile Expiration Date: " -NoNewline
                    write-host "$($ProfileExpirationDate)" -ForegroundColor Yellow 

            }

            else {
            
                    Write-Host "iOS App Provisioning Profile: $($ProfileExpirationDate)"

            }

        
        Write-Host
        write-host "-------------------------------------------------------------------"
        write-host
        
    
    }

    if (!($Profiles.count -eq 0)) {

    Write-Host "Export results? [Y]es, [N]o"
    $conf = Read-Host
 
        if ($conf -eq "Y"){

        $parent = [System.IO.Path]::GetTempPath()
        [string] $name = [System.Guid]::NewGuid()
        New-Item -ItemType Directory -Path (Join-Path $parent $name) | Out-Null
        $TempDirPath = "$parent$name" 
        $TempExportFilePath = "$($TempDirPath)\iOSAppProvisioningProfileExport.txt"
        $CSV | Add-Content $TempExportFilePath -Force
        Write-Host
        Write-Host "$($TempExportFilePath)"
        Write-Host

        }

    }

    else {
    
        write-host "No iOS App Provisioning Profiles found."
        write-host

    }
