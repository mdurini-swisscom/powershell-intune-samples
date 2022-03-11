
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################


    
    ####################################################
    
    Function Get-AADUser(){
    
    <#
    .SYNOPSIS
    This function is used to get AAD Users from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any users registered with AAD
    .EXAMPLE
    Get-AADUser
    Returns all users registered with Azure AD
    .EXAMPLE
    Get-AADUser -userPrincipleName user@domain.com
    Returns specific user by UserPrincipalName registered with Azure AD
    .NOTES
    NAME: Get-AADUser
    #>
    
    [cmdletbinding()]
    
    param
    (
        $userPrincipalName,
        $Property
    )
    
    # Defining Variables
    $graphApiVersion = "v1.0"
    $User_resource = "users"
        
        try {
            
            if($userPrincipalName -eq "" -or $userPrincipalName -eq $null){
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            
            }
    
            else {
                
                if($Property -eq "" -or $Property -eq $null){
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
                Write-Verbose $uri
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
                }
    
                else {
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
                Write-Verbose $uri
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
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
    
    ####################################################
    
    
    
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
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/roleDefinitions"
        
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
    
    ####################################################
    
    Function Get-RBACRoleDefinition(){
    
    <#
    .SYNOPSIS
    This function is used to get an RBAC Role Definition from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any RBAC Role Definition
    .EXAMPLE
    Get-RBACRoleDefinition -id $id
    Returns an RBAC Role Definitions configured in Intune
    .NOTES
    NAME: Get-RBACRoleDefinition
    #>
    
    [cmdletbinding()]
    
    param
    (
        $id
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/roleDefinitions('$id')?`$expand=roleassignments"
        
        try {
    
            if(!$id){
    
            write-host "No Role ID was passed to the function, provide an ID variable" -f Red
            break
    
            }
        
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).roleAssignments
        
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
    
    Function Get-RBACRoleAssignment(){
    
    <#
    .SYNOPSIS
    This function is used to get an RBAC Role Assignment from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any RBAC Role Assignment
    .EXAMPLE
    Get-RBACRoleAssignment -id $id
    Returns an RBAC Role Assignment configured in Intune
    .NOTES
    NAME: Get-RBACRoleAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        $id
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/roleAssignments('$id')?`$expand=microsoft.graph.deviceAndAppManagementRoleAssignment/roleScopeTags"
        
        try {
    
            if(!$id){
    
            write-host "No Role Assignment ID was passed to the function, provide an ID variable" -f Red
            break
    
            }
        
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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
    
    write-host
    write-host "Please specify the User Principal Name you want to query:" -f Yellow
    $UPN = Read-Host
    
        if($UPN -eq $null -or $UPN -eq ""){
    
        Write-Host "Valid UPN not specified, script can't continue..." -f Red
        Write-Host
        break
    
        }
    
    $User = Get-AADUser -userPrincipalName $UPN
    
    $UserID = $User.id
    $UserDN = $User.displayName
    $UserPN = $User.userPrincipalName
    
    Write-Host
    write-host "-------------------------------------------------------------------"
    write-host
    write-host "Display Name:"$User.displayName
    write-host "User ID:"$User.id
    write-host "User Principal Name:"$User.userPrincipalName
    write-host
    
    ####################################################
    
    $MemberOf = Get-AADUser -userPrincipalName $UPN -Property MemberOf
    
    $DirectoryRole = $MemberOf | ? { $_.'@odata.type' -eq "#microsoft.graph.directoryRole" }
    
        if($DirectoryRole){
    
        $DirRole = $DirectoryRole.displayName
    
        write-host "Directory Role:" -f Yellow
        $DirectoryRole.displayName
        write-host
    
        }
    
        else {
    
        write-host "Directory Role:" -f Yellow
        Write-Host "User"
        write-host
    
        }
    
    ####################################################
    
    $AADGroups = $MemberOf | ? { $_.'@odata.type' -eq "#microsoft.graph.group" } | sort displayName
    
        if($AADGroups){
    
        write-host "AAD Group Membership:" -f Yellow
            
            foreach($AADGroup in $AADGroups){
            
            $GroupDN = (Get-AADGroup -id $AADGroup.id).displayName
    
            $GroupDN
    
            }
    
        write-host
    
        }
    
        else {
    
        write-host "AAD Group Membership:" -f Yellow
        write-host "No Group Membership in AAD Groups"
        Write-Host
    
        }
    
    ####################################################
    
    write-host "-------------------------------------------------------------------"
    
    # Getting all Intune Roles defined
    $RBAC_Roles = Get-RBACRole
    
    $UserRoleCount = 0
    
    $Permissions = @()
    
    # Looping through all Intune Roles defined
    foreach($RBAC_Role in $RBAC_Roles){
    
    $RBAC_id = $RBAC_Role.id
    
    $RoleAssignments = Get-RBACRoleDefinition -id $RBAC_id
        
        # If an Intune Role has an Assignment check if the user is a member of members group
        if($RoleAssignments){
    
            $RoleAssignments | foreach {
    
            $RBAC_Role_Assignments = $_.id
    
            $Assignment = Get-RBACRoleAssignment -id $RBAC_Role_Assignments
    
            $RA_Names = @()
    
            $Members = $Assignment.members
            $ScopeMembers = $Assignment.scopeMembers
            $ScopeTags = $Assignment.roleScopeTags
    
                $Members | foreach {
    
                    if($AADGroups.id -contains $_){
    
                    $RA_Names += (Get-AADGroup -id $_).displayName
    
                    }
    
                }
    
                if($RA_Names){
    
                $UserRoleCount++
    
                Write-Host
                write-host "RBAC Role Assigned: " $RBAC_Role.displayName -ForegroundColor Cyan
                $Permissions += $RBAC_Role.permissions.actions
                Write-Host
    
                write-host "Assignment Display Name:" $Assignment.displayName -ForegroundColor Yellow
                Write-Host
    
                Write-Host "Assignment - Members:" -f Yellow 
                $RA_Names
    
                Write-Host
                Write-Host "Assignment - Scope (Groups):" -f Yellow
                
                    if($Assignment.scopeType -eq "resourceScope"){
                    
                        $ScopeMembers | foreach {
    
                        (Get-AADGroup -id $_).displayName
    
                        }
    
                    }
    
                    else {
    
                        Write-Host ($Assignment.ScopeType -creplace  '([A-Z\W_]|\d+)(?<![a-z])',' $&').trim()
    
                    }
    
                Write-Host
                Write-Host "Assignment - Scope Tags:" -f Yellow
                    
                    if($ScopeTags){
    
                        $AllScopeTags += $ScopeTags 
    
                        $ScopeTags | foreach {
    
                            $_.displayName
    
                        }
    
                    }
    
                    else {
    
                        Write-Host "No Scope Tag Assigned to the Role Assignment..." -f Red
    
                    }
    
                Write-Host
                Write-Host "Assignment - Permissions:" -f Yellow
                
                $RolePermissions = $RBAC_Role.permissions.actions | foreach { $_.replace("Microsoft.Intune_","") }
                
                $RolePermissions | sort
    
                $ScopeTagPermissions += $RolePermissions | foreach { $_.split("_")[0] } | select -Unique | sort
    
                Write-Host
                write-host "-------------------------------------------------------------------"
    
                }
    
            }
    
        }
    
    }
    
    ####################################################
    
    if($Permissions){
    
    Write-Host
    write-host "Effective Permissions for user:" -ForegroundColor Yellow
    
    $Permissions = $Permissions | foreach { $_.replace("Microsoft.Intune_","") }
    
    $Permissions | select -Unique | sort
    
    }
    
    else {
    
    Write-Host
    write-host "User isn't part of any Intune Roles..." -ForegroundColor Yellow
    
    }
    
    Write-Host
    
    
    ####################################################
    