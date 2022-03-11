
<#
 
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

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

$batch = @"

{
  "requests": [
    {
      "id": "1",
      "method": "GET",
      "url": "/deviceManagement/deviceCompliancePolicies"
    },
    {
      "id": "2",
      "method": "GET",
      "url": "/deviceManagement/deviceConfigurations"
    },
    {
      "id": "3",
      "method": "GET",
      "url": "/deviceAppManagement/mobileApps"
    }
  ]
}

"@

####################################################

$uri = "https://graph.microsoft.com/beta/`$batch"

$Post = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $batch -ContentType "application/json"

foreach($Element in $Post.responses.body){

    Write-Host $Element.'@odata.context' -ForegroundColor Cyan
    Write-Host "Reponse Count:"$Element.value.count -ForegroundColor Yellow
    $Element.value.displayName
    Write-Host

}