
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

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

$parent = [System.IO.Path]::GetTempPath()
[string] $name = [System.Guid]::NewGuid()
New-Item -ItemType Directory -Path (Join-Path $parent $name) | Out-Null
$TempDirPath = "$parent$name"

####################################################

$Profiles = Get-AndroidEnrollmentProfile

if($profiles){

$profilecount = @($profiles).count

    if(@($profiles).count -gt 1){

    Write-Host "Corporate-owned dedicated device profiles found: $profilecount"
    Write-Host

    $COSUprofiles = $profiles.Displayname | Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $COSUprofiles.count; $i++) 
    { Write-Host "$i. $($COSUprofiles[$i-1])" 
    $menu.Add($i,($COSUprofiles[$i-1]))}

    Write-Host
    $ans = Read-Host 'Choose a profile (numerical value)'

    if($ans -eq "" -or $ans -eq $null){

        Write-Host "Corporate-owned dedicated device profile can't be null, please specify a valid Profile..." -ForegroundColor Red
        Write-Host
        break

    }

    elseif(($ans -match "^[\d\.]+$") -eq $true){

    $selection = $menu.Item([int]$ans)

    Write-Host

        if($selection){

            $SelectedProfile = $profiles | ? { $_.DisplayName -eq "$Selection" }

            $SelectedProfileID = $SelectedProfile | select -ExpandProperty id

            $ProfileID = $SelectedProfileID

            $ProfileDisplayName = $SelectedProfile.displayName

        }

        else {

            Write-Host "Corporate-owned dedicated device profile selection invalid, please specify a valid Profile..." -ForegroundColor Red
            Write-Host
            break

        }

    }

    else {

        Write-Host "Corporate-owned dedicated device profile selection invalid, please specify a valid Profile..." -ForegroundColor Red
        Write-Host
        break

    }

}

    elseif(@($profiles).count -eq 1){

        $Profileid = (Get-AndroidEnrollmentProfile).id
        $ProfileDisplayName = (Get-AndroidEnrollmentProfile).displayname
    
        Write-Host "Found a Corporate-owned dedicated devices profile '$ProfileDisplayName'..."
        Write-Host

    }

    else {

        Write-Host
        write-host "No enrollment profiles found!" -f Yellow
        break

    }

Write-Warning "You are about to export the QR code for the Dedicated Device Enrollment Profile '$ProfileDisplayName'"
Write-Warning "Anyone with this QR code can Enrol a device into your tenant. Please ensure it is kept secure."
Write-Warning "If you accidentally share the QR code, you can immediately expire it in the Intune UI."
write-warning "Devices already enrolled will be unaffected."
Write-Host
Write-Host "Show token? [Y]es, [N]o"

$FinalConfirmation = Read-Host

    if ($FinalConfirmation -ne "y"){
    
        Write-Host "Exiting..."
        Write-Host
        break

    }

    else {

    Write-Host

    $QR = (Get-AndroidQRCode -Profileid $ProfileID)
    
    $QRType = $QR.qrCodeImage.type
    $QRValue = $QR.qrCodeImage.value
 
    $imageType = $QRType.split("/")[1]
 
    $filename = "$TempDirPath\$ProfileDisplayName.$imageType"

    $bytes = [Convert]::FromBase64String($QRValue)
    [IO.File]::WriteAllBytes($filename, $bytes)

        if (Test-Path $filename){

            Write-Host "Success: " -NoNewline -ForegroundColor Green
            write-host "QR code exported to " -NoNewline
            Write-Host "$filename" -ForegroundColor Yellow
            Write-Host

        }

        else {
        
            write-host "Oops! Something went wrong!" -ForegroundColor Red
        
        }
       
    }

}

else {

    Write-Host "No Corporate-owned dedicated device Profiles found..." -ForegroundColor Yellow
    Write-Host

}