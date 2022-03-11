<#
.COPYRIGHT		
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
	
#>
####################################################



####################################################

Function Get-TermsAndConditions(){

<#
.SYNOPSIS
This function is used to get the Get Terms And Conditions intune resource from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets the Terms and Conditions Intune Resource
.EXAMPLE
Get-TermsAndConditions
Returns the Organization resource configured in Intune
.NOTES
NAME: Get-TermsAndConditions
#>

[cmdletbinding()]

param
(
    $Name
)

$graphApiVersion = "Beta"
$resource = "deviceManagement/termsAndConditions"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

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

Function Export-JSONData(){
	
<#
.SYNOPSIS
This function is used to export JSON data returned from Graph
.DESCRIPTION
This function is used to export JSON data returned from Graph
.EXAMPLE
Export-JSONData -JSON $JSON
Export the JSON inputted on the function
.NOTES
NAME: Export-JSONData
#>
        
param (
    
    $JSON,
    $ExportPath
    
)
        
    try
    {
        
        if ($JSON -eq "" -or $JSON -eq $null)
        {
            
            write-host "No JSON specified, please specify valid JSON..." -f Red
            
        }
        
        elseif (!$ExportPath)
        {
            
            write-host "No export path parameter set, please provide a path to export the file" -f Red
            
        }
        
        elseif (!(Test-Path $ExportPath))
        {
            
            write-host "$ExportPath doesn't exist, can't export JSON Data" -f Red
            
        }
        
        else
        {
            
            $JSON1 = ConvertTo-Json $JSON
            
            $JSON_Convert = $JSON1 | ConvertFrom-Json
            
            $displayName = $JSON_Convert.displayName

            # Updating display name to follow file naming conventions - https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
            $DisplayName = $DisplayName -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
            
            $Properties = ($JSON_Convert | Get-Member | ? { $_.MemberType -eq "NoteProperty" }).Name
            
            $FileName_CSV = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".csv"
            $FileName_JSON = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json"
            
            $Object = New-Object System.Object
            
            foreach ($Property in $Properties)
            {
                
                $Object | Add-Member -MemberType NoteProperty -Name $Property -Value $JSON_Convert.$Property
                
            }
            
            write-host "Export Path:" "$ExportPath"
            
            $Object | Export-Csv -LiteralPath "$ExportPath\$FileName_CSV" -Delimiter "," -NoTypeInformation -Append
            $JSON1 | Set-Content -LiteralPath "$ExportPath\$FileName_JSON"
            write-host "CSV created in $ExportPath\$FileName_CSV..." -f cyan
            write-host "JSON created in $ExportPath\$FileName_JSON..." -f cyan
            
        }
        
    }
    
    catch
    {
        
        $_.Exception
        
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

$ExportPath = Read-Host -Prompt "Please specify a path to export the policy data to e.g. C:\IntuneOutput"

# If the directory path doesn't exist prompt user to create the directory

if (!(Test-Path "$ExportPath"))
{
	
	Write-Host
	Write-Host "Path '$ExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow
	
	$Confirm = read-host
	
	if ($Confirm -eq "y" -or $Confirm -eq "Y")
	{
		
		new-item -ItemType Directory -Path "$ExportPath" | Out-Null
		Write-Host
		
	}
	
	else
	{
		
		Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
		Write-Host
		break
		
	}
	
}

Write-Host

####################################################

$TCs = Get-TermsAndConditions

foreach ($TC in $TCs)
{
	
	write-host "Terms and Conditions Policy:"$TSc.displayName -f Yellow
	Export-JSONData -JSON $TC -ExportPath "$ExportPath"
	Write-Host
	
}
