<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################



####################################################

Function Export-iOSDevices(){

<#
.SYNOPSIS
This function is used to export iOS Devices from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and exports iOS devices
.EXAMPLE
Export-Devices
Returns any iOS Device enrolled into Intune
.NOTES
NAME: Export-iOSDevices
#>

[cmdletbinding()]

param
(
$Name
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/reports/exportJobs"

    try {

    $properties = @{

        reportName = 'Devices'
        select = @('DeviceId',"DeviceName","OSVersion", "HasUnlockToken")
        filter = "((DeviceType eq '14') or (DeviceType eq '9') or (DeviceType eq '8') or (DeviceType eq '10'))"
    
    }

    $psObj = New-Object -TypeName psobject -Property $properties

    $Json = ConvertTo-Json -InputObject $psObj

    if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

    }

    else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $result = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json")

        $id = $result.id

        write-host "Export Job id is '$id'" -ForegroundColor Cyan

        Write-Host

            while($true){

                $pollingUri = "$uri('$id')"
                write-host "Polling uri = "$pollingUri

                $result = (Invoke-RestMethod -Uri $pollingUri -Headers $authToken -Method Get)
                $status = $result.status

                if ($status -eq 'completed'){

                    Write-Host "Export Job Complete..." -ForegroundColor Green
                    Write-Host

                    $fileName = (Split-Path -Path $result.url -Leaf).split('?')[0]

                    Invoke-WebRequest -Uri $result.url -OutFile $env:temp\$fileName

                    Write-host "Downloaded Export to local disk as '$env:temp\$fileName'..." -ForegroundColor Green
                    Write-Host
                    break;

                }

                else {

                    Write-Host "In progress, waiting..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 5
                    Write-Host
        
                }

            }

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

Export-iOSDevices