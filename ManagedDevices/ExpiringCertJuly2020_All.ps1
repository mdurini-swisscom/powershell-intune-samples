
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

param(

    [Parameter(Mandatory = $true, HelpMessage = "File path and name for output of expiring devices")]
    $OutputFile

)

####################################################



####################################################

function Get-MsGraphCollection {

param
(
    [Parameter(Mandatory = $true)]
    $Uri,
        
    [Parameter(Mandatory = $true)]
    $AuthHeader
)

    $Collection = @()
    $NextLink = $Uri
    $CertExpiration = [datetime]'2020-07-12 12:00:00'  #(Get-Date -Year 2019 -Month 4 -Day 21 -Hour 14 -Minute 48)

    do {

        try {

            Write-Host "GET $NextLink"
            $Result = Invoke-RestMethod -Method Get -Uri $NextLink -Headers $AuthHeader

            foreach ($d in $Result.value)
            {
                if ([datetime]($d.managementCertificateExpirationDate) -le $CertExpiration)
                {
                    $Collection += $d
                }
            }
            $NextLink = $Result.'@odata.nextLink'
        } 

        catch {

            $ResponseStream = $_.Exception.Response.GetResponseStream()
            $ResponseReader = New-Object System.IO.StreamReader $ResponseStream
            $ResponseContent = $ResponseReader.ReadToEnd()
            Write-Host "Request Failed: $($_.Exception.Message)`n$($_.ErrorDetails)"
            Write-Host "Request URL: $NextLink"
            Write-Host "Response Content:`n$ResponseContent"
            break

        }

    } while ($NextLink -ne $null)

    return $Collection
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

$uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=((managementAgent%20eq%20%27mdm%27%20or%20managementAgent%20eq%20%27easmdm%27%20or%20managementAgent%20eq%20%27configurationmanagerclientmdm%27%20or%20managementAgent%20eq%20%27configurationmanagerclientmdmeas%27)%20and%20managementState%20eq%20%27managed%27)"

$devices = Get-MsGraphCollection -Uri $uri -AuthHeader $authToken

Write-Host
Write-Host "Found" $devices.Count "devices:"
Write-Host "Writing results to" $OutputFile -ForegroundColor Cyan

($devices | Select-Object Id, DeviceName, DeviceType, IMEI, UserPrincipalName, SerialNumber, LastSyncDateTime, ManagementCertificateExpirationDate) | Export-Csv -Path $OutputFile -NoTypeInformation 

$devices | Select-Object Id, DeviceName, DeviceType, IMEI, UserPrincipalName, SerialNumber, LastSyncDateTime, ManagementCertificateExpirationDate

Write-Host "Results written to" $OutputFile -ForegroundColor Yellow