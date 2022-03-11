
<#
  Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

<#

.SYNOPSIS
  Name: Configure-MDATPIntuneSecAdminRole.ps1
  Configures MDATP Intune environment by creating a custom role and assignment with permissions to read security baseline data and machine onboarding data.

.DESCRIPTION
  Configures MDATP Intune environment by creating a custom role and assignment with permissions to read security baseline data and machine onboarding data.
  Populates the role assignment with security groups provided by the SecurityGroupList parameter. 
  Any users or groups added to the new role assignment will inherit the permissions of the role and gain read access to security baseline data and machine onboarding data.
  Use an elevated command prompt (run as local admin) from a machine with access to your Microsoft Defender ATP environment. 
  The script needs to run as local admin to install the Azure AD PowerShell module if not already present.

.PARAMETER AdminUser
  User with global admin privileges in your Intune environment  

.PARAMETER SecAdminGroup
  Security group name - Security group that contains SecAdmin users. Supports only one group. Create a group first if needed. Specify SecAdminGroup param or SecurityGroupList param, but not both.

.PARAMETER SecurityGroupList
  Path to txt file containing list of ObjectIds for security groups to add to Intune role. One ObjectId per line. Specify SecAdminGroup param or SecurityGroupList param, but not both.

.EXAMPLE
  Configure-MDATPIntuneSecAdminRole.ps1 -AdminUser admin@tenant.onmicrosoft.com -SecAdminGroup MySecAdminGroup
  Connects to Azure Active Directory environment myMDATP.mydomain.com, creates a custom role with permission to read security baseline data, and populates it with the specified SecAdmin security group

.EXAMPLE
  Configure-MDATPIntuneSecAdminRole.ps1 -AdminUser admin@tenant.onmicrosoft.com -SecurityGroupList .\SecurityGroupList.txt
  Connects to Azure Active Directory environment myMDATP.mydomain.com, creates a custom role with permission to read security baseline data, and populates it with security groups from SecurityGroupList.txt
  SecurityGroupList txt file must contain list of ObjectIds for security groups to add to Intune role. One ObjectId per line.

.NOTES
  This script uses functions provided by Microsoft Graph team:
  Microsoft Graph API's for Intune: https://developer.microsoft.com/en-us/graph/docs/api-reference/beta/resources/intune_graph_overview
  Sample PowerShell Scripts: https://github.com/microsoftgraph/powershell-intune-samples
  https://github.com/microsoftgraph/powershell-intune-samples/tree/master/RBAC

#>

[CmdletBinding()]

Param(

    [Parameter(Mandatory=$true, HelpMessage="AdminUser@myenvironment.onmicrosoft.com")]
    $AdminUser,

    [Parameter(Mandatory=$false, HelpMessage="MySecAdminGroup")]
    [string]$SecAdminGroup,

    [Parameter(Mandatory=$false, HelpMessage="c:\mylist.txt")]
    $SecurityGroupList

)

####################################################
# Parameters
####################################################

if ($SecurityGroupList){

    $SecurityGroupList = Get-Content "$SecurityGroupList"

}

$AADEnvironment = (New-Object "System.Net.Mail.MailAddress" -ArgumentList $AdminUser).Host

$RBACRoleName    = "MDATP SecAdmin"  
$SecurityGroup   = "MDATP SecAdmin SG"  
$User = $AdminUser

####################################################
# Functions
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

Function Add-RBACRole(){

<#
.SYNOPSIS
This function is used to add an RBAC Role Definitions from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds an RBAC Role Definitions
.EXAMPLE
Add-RBACRole -JSON $JSON
.NOTES
NAME: Add-RBACRole
#>

[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions"

    try {

        if(!$JSON){

        Write-Host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $Json -ContentType "application/json"

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

Function Get-RBACRole(){

  <#
  .SYNOPSIS
  This function is used to get RBAC Role Definitions from the Graph API REST interface
  .DESCRIPTION
  The function connects to the Graph API Interface and gets any RBAC Role Definitions
  .EXAMPLE
  Get-RBACRole
  Returns any RBAC Role Definitions configured in Intune
  .NOTES
  NAME: Get-RBACRole
  #>
  
  [cmdletbinding()]
  
  param
  (
      $Name
  )
  
  $graphApiVersion = "v1.0"
  $Resource = "deviceManagement/roleDefinitions"
  
      try {
  
        if($Name){
          $QueryString = "?`$filter=contains(displayName, '$Name')"
          $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)$($QueryString)"
          $rbacRoles = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
          $customRbacRoles = $rbacRoles | Where-Object { $_isBuiltInRoleDefinition -eq $false }
          return $customRbacRoles
        }
  
          else {
  
          $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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
      Write-Host
      break
  
      }
  
}

####################################################
  
Function Assign-RBACRole(){

<#
.SYNOPSIS
This function is used to set an assignment for an RBAC Role using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and sets and assignment for an RBAC Role
.EXAMPLE
Assign-RBACRole -Id $IntuneRoleID -DisplayName "Assignment" -MemberGroupId $MemberGroupId -TargetGroupId $TargetGroupId
Creates and Assigns and Intune Role assignment to an Intune Role in Intune
.NOTES
NAME: Assign-RBACRole
#>

[cmdletbinding()]

param
(
    $Id,
    $DisplayName,
    $MemberGroupId,
    $TargetGroupId
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleAssignments"
    
    try {

        if(!$Id){

        Write-Host "No Policy Id specified, specify a valid Application Id" -f Red
        break

        }

        if(!$DisplayName){

        Write-Host "No Display Name specified, specify a Display Name" -f Red
        break

        }

        if(!$MemberGroupId){

        Write-Host "No Member Group Id specified, specify a valid Target Group Id" -f Red
        break

        }

        if(!$TargetGroupId){

        Write-Host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        break

        }


$JSON = @"
    {
    "id":"",
    "description":"",
    "displayName":"$DisplayName",
    "members":["$MemberGroupId"],
    "scopeMembers":["$TargetGroupId"],
    "roleDefinition@odata.bind":"https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('$ID')"
    }
"@

    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
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
  
            $User = Read-Host -Prompt "Please specify your Global Admin user for Azure Authentication (e.g. globaladmin@myenvironment.onmicrosoft.com):"
            Write-Host
  
            }
  
        $global:authToken = Get-AuthToken -User $User
  
        }
}
  
# Authentication doesn't exist, calling Get-AuthToken function
  
else {
  
    if($User -eq $null -or $User -eq ""){
  
    $User = Read-Host -Prompt "Please specify your Global Admin user for Azure Authentication (e.g. globaladmin@myenvironment.onmicrosoft.com):"
    Write-Host
  
    }
  
# Getting the authorization token
$global:authToken = Get-AuthToken -User $User
  
}
  
#endregion
  
####################################################

$JSON = @"
{
  "@odata.type": "#microsoft.graph.roleDefinition",
  "displayName": "$RBACRoleName",
  "description": "Role with access to modify Intune SecuriyBaselines and DeviceConfigurations",
  "permissions": [
    {
      "actions": [
        "Microsoft.Intune_Organization_Read",
        "Microsoft.Intune/SecurityBaselines/Assign",
        "Microsoft.Intune/SecurityBaselines/Create",
        "Microsoft.Intune/SecurityBaselines/Delete",
        "Microsoft.Intune/SecurityBaselines/Read",
        "Microsoft.Intune/SecurityBaselines/Update",
        "Microsoft.Intune/DeviceConfigurations/Assign",
        "Microsoft.Intune/DeviceConfigurations/Create",
        "Microsoft.Intune/DeviceConfigurations/Delete",
        "Microsoft.Intune/DeviceConfigurations/Read",
        "Microsoft.Intune/DeviceConfigurations/Update"
      ]
    }
  ],
  "isBuiltInRoleDefinition": false
}
"@
  
####################################################
# Main
####################################################

Write-Host "Configuring MDATP Intune SecAdmin Role..." -ForegroundColor Cyan
Write-Host
Write-Host "Connecting to Azure AD environment: $AADEnvironment..." -ForegroundColor Yellow
Write-Host

$RBAC_Roles = Get-RBACRole

# Checking if Intune Role already exist with $RBACRoleName
if($RBAC_Roles | Where-Object { $_.displayName -eq "$RBACRoleName" }){

    Write-Host "Intune Role already exists with name '$RBACRoleName'..." -ForegroundColor Red
    Write-Host "Script can't continue..." -ForegroundColor Red
    Write-Host
    break

}

# Add new RBAC Role
Write-Host "Adding new RBAC Role: $RBACRoleName..." -ForegroundColor Yellow
Write-Host "JSON:"
Write-Host $JSON
Write-Host

$NewRBACRole = Add-RBACRole -JSON $JSON
$NewRBACRoleID = $NewRBACRole.id

# Get Id for new Role
Write-Host "Getting Id for new role..." -ForegroundColor Yellow
$Updated_RBAC_Roles = Get-RBACRole

$NewRBACRoleID = ($Updated_RBAC_Roles | Where-Object {$_.displayName -eq "$RBACRoleName"}).id

Write-Host "$NewRBACRoleID"
Write-Host

####################################################

if($SecAdminGroup){

  # Verify group exists
  Write-Host "Verifying group '$SecAdminGroup' exists..." -ForegroundColor Yellow

  Connect-AzureAD -AzureEnvironmentName AzureCloud -AccountId $AdminUser | Out-Null
  $ValidatedSecAdminGroup = (Get-AzureADGroup -SearchString $SecAdminGroup).ObjectId

  if ($ValidatedSecAdminGroup){

    Write-Host "AAD Group '$SecAdminGroup' exists" -ForegroundColor Green
    Write-Host ""
    Write-Host "Adding AAD group $SecAdminGroup - $ValidatedSecAdminGroup to MDATP Role..." -ForegroundColor Yellow
    
    # Verify security group list only contains valid GUIDs
    try {

      [System.Guid]::Parse($ValidatedSecAdminGroup) | Out-Null
      Write-Host "ObjectId: $ValidatedSecAdminGroup" -ForegroundColor Green
      Write-Host

    }
    
    catch {
    
        Write-Host "ObjectId: $ValidatedSecAdminGroup is not a valid ObjectId" -ForegroundColor Red
        Write-Host "Verify that your security group list only contains valid ObjectIds and try again." -ForegroundColor Cyan
        exit -1
    
    }

  Write-Host "Adding security group to RBAC role $RBACRoleName ..." -ForegroundColor Yellow

  Assign-RBACRole -Id $NewRBACRoleID -DisplayName 'MDATP RBAC Assignment' -MemberGroupId $ValidatedSecAdminGroup -TargetGroupId "default"
  # NOTE: TargetGroupID = Scope Group

  }
  
  else {

    Write-Host "Group '$SecAdminGroup' does not exist. Please run script again and specify a valid group." -ForegroundColor Red
    Write-Host
    break
  
  }

}

####################################################

if($SecurityGroupList){

  Write-Host "Validating Security Groups to add to Intune Role:" -ForegroundColor Yellow

  foreach ($SecurityGroup in $SecurityGroupList) {
    
    # Verify security group list only contains valid GUIDs
    try {

      [System.Guid]::Parse($SecurityGroup) | Out-Null
      Write-Host "ObjectId: $SecurityGroup" -ForegroundColor Green
    
    }
    
    catch {

        Write-Host "ObjectId: $SecurityGroup is not a valid ObjectId" -ForegroundColor Red
        Write-Host "Verify that your security group list only contains valid ObjectIds and try again." -ForegroundColor Cyan
        exit -1
    
    }

  }

  # Format list for Assign-RBACRole function
  $ValidatedSecurityGroupList = $SecurityGroupList -join "`",`""

  $SecurityGroupList
  $ValidatedSecurityGroupList

  Write-Host ""
  Write-Host "Adding security groups to RBAC role '$RBACRoleName'..." -ForegroundColor Yellow

  Assign-RBACRole -Id $NewRBACRoleID -DisplayName 'MDATP RBAC Assignment' -MemberGroupId $ValidatedSecurityGroupList -TargetGroupId "default"
  # NOTE: TargetGroupID = Scope Group

}

####################################################

Write-Host "Retrieving permissions for new role: $RBACRoleName..." -ForegroundColor Yellow
Write-Host

$RBAC_Role = Get-RBACRole | Where-Object { $_.displayName -eq "$RBACRoleName" }

Write-Host $RBAC_Role.displayName -ForegroundColor Green
Write-Host $RBAC_Role.id -ForegroundColor Cyan
$RBAC_Role.RolePermissions.resourceActions.allowedResourceActions
Write-Host

####################################################

Write-Host "Members of RBAC Role '$RBACRoleName' should now have access to Security Baseline and" -ForegroundColor Cyan
write-host "Onboarded machines tiles in Microsoft Defender Security Center." -ForegroundColor Cyan
Write-Host
Write-Host "https://securitycenter.windows.com/configuration-management"
Write-Host
Write-Host "Add users and groups to the new role assignment 'MDATP RBAC Assignment' as needed." -ForegroundColor Cyan

Write-Host
Write-Host "Configuration of MDATP Intune SecAdmin Role complete..." -ForegroundColor Green
Write-Host
