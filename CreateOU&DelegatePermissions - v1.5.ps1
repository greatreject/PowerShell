##########################################################
#    CreateOU&DelegatePermissions                        #
#    Created by Amit Patel                               #
#    26/11/2020                                          #
##########################################################

# Main menu, allowing user selection
function Show-Menu
{
     param (
           [string]$Title = 'Domain Selection Menu'
     )
     cls
     Write-Host "================ $Title ================"
    
     Write-Host "1: Press '1' for LEO"
     Write-Host "2: Press '2' for RWETD"
     Write-Host "q: Press 'q' to Quit"
}

#Functions
Function LEO {

Import-Module ActiveDirectory
Write-Host 'Enter LEO Domain Credentials' 
New-PSDrive LEO -PSProvider ActiveDirectory -Server "LEO.INFRA.COM" -Root "//RootDSE/" -Credential "" -Scope Global
cls
cd LEO:

#Reads in both Inputs for the Account ID OU Name and the OU Path for the enviroment
$leo_name = Read-Host -Prompt 'Input Name of the Account ID to be created'
#$leo_path = Read-Host -Prompt 'Input which environment OU will be created for (NoPrd, Prd or UAT)'
 
do{   
    
    $leo_path = Read-Host -Prompt 'Input which environment OU will be created for (NoPrd, Prd or UAT)'
    if ($leo_path -in "NoPrd", "Prd", "UAT") {$continue=$true}
         else {Write-Host "You have entered an invalid OU Path name. Please try again!" -ForegroundColor Red -BackgroundColor Yellow}
  }
    until ($continue)



#Creates the OU's in the correct locations depending on the inputs above
New-ADOrganizationalUnit -Name "$leo_name" -Path "OU=$leo_path,OU=Accounts,OU=AWS,DC=LEO,DC=INFRA,DC=COM" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "$leo_name" -Path "OU=$leo_path,OU=Servers,OU=AWS,DC=LEO,DC=INFRA,DC=COM" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "$leo_name" -Path "OU=$leo_path,OU=Groups,OU=AWS,DC=LEO,DC=INFRA,DC=COM" -ProtectedFromAccidentalDeletion $false
$ouname1 = "OU=$leo_name," + "OU=$leo_path,OU=Accounts,OU=AWS,DC=LEO,DC=INFRA,DC=COM"
$ouname2 = "OU=$leo_name," + "OU=$leo_path,OU=Servers,OU=AWS,DC=LEO,DC=INFRA,DC=COM"
$ouname3 = "OU=$leo_name," + "OU=$leo_path,OU=Groups,OU=AWS,DC=LEO,DC=INFRA,DC=COM"


#Creates the Delegated Group OU dependant on the initial inputs
$dlgou = "OU=Groups,OU=Admin,OU=AWS,DC=LEO,DC=INFRA,DC=COM"
If ($leo_path -eq "UAT") {
$newdlg = New-ADGroup "awsu-l-dlg-$leo_name" -Path $dlgou -GroupCategory Security -GroupScope DomainLocal -PassThru –Verbose
}
Elseif ($leo_path -eq "Prd") {
$newdlg = New-ADGroup "awsp-l-dlg-$leo_name" -Path $dlgou -GroupCategory Security -GroupScope DomainLocal -PassThru –Verbose
}
Elseif ($leo_path -eq "NoPrd") {
$newdlg = New-ADGroup "awsn-l-dlg-$leo_name" -Path $dlgou -GroupCategory Security -GroupScope DomainLocal -PassThru –Verbose
}

#Reads in the OU Names and Delegated Group from inputs
$ou1 = Get-ADOrganizationalUnit -Identity $ouname1 | Select-Object -ExpandProperty DistinguishedName
$ou2 = Get-ADOrganizationalUnit -Identity $ouname2 | Select-Object -ExpandProperty DistinguishedName
$ou3 = Get-ADOrganizationalUnit -Identity $ouname3 | Select-Object -ExpandProperty DistinguishedName
$group = Get-ADGroup $newdlg
#Creates a variable from the Delegated Group that can be used to apply permissions. .NET is parameters are used to achieve this
$sid = new-object System.Security.Principal.SecurityIdentifier $group.SID
#Reads in the ACL path for the OU's
$acl1 = get-acl -Path "$ou1"
$acl2 = get-acl -Path "$ou2"
$acl3 = get-acl -Path "$ou3"
#Schema GUID's read in for Computer, User and Group objects
$servers = [GUID]"bf967a86-0de6-11d0-a285-00aa003049e2"
$accounts = [GUID]"bf967aba-0de6-11d0-a285-00aa003049e2"
$groups = [GUID]"bf967a9c-0de6-11d0-a285-00aa003049e2"
#Permissions are declared for the Delegated Group against each Schema GUID type
$ace1 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild","Allow","Descendents", $accounts
$ace2 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"DeleteChild", "Allow","Descendents", $accounts
$ace3 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"WriteProperty", "Allow","Descendents", $accounts
$ace4 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild","Allow","Descendents", $servers
$ace5 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"DeleteChild", "Allow","Descendents", $servers
$ace6 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild","Allow","Descendents", $groups
$ace7 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"DeleteChild", "Allow","Descendents", $groups
$ace8 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"WriteProperty", "Allow","Descendents", $groups
#Access rules mapped between OU's and Delegated Group
$acl1.AddAccessRule($ace1)
$acl1.AddAccessRule($ace2)
$acl1.AddAccessRule($ace3)
$acl2.AddAccessRule($ace4)
$acl2.AddAccessRule($ace5)
$acl3.AddAccessRule($ace6)
$acl3.AddAccessRule($ace7)
$acl3.AddAccessRule($ace8)
#Permissions applied to the relevant OU based on mapping above
set-acl -Path "$ou1" -AclObject $acl1
set-acl -Path "$ou2" -AclObject $acl2
set-acl -Path "$ou3" -AclObject $acl3
#Remove PSDrive
c:
Remove-PSDrive LEO
Exit
}



Function RWETD {

Import-Module ActiveDirectory
Write-Host 'Enter RWETD Domain Credentials' 
New-PSDrive RWETD -PSProvider ActiveDirectory -Server "RWETD.COM" -Root "//RootDSE/" -Credential "" -Scope Global
cls
cd RWETD:

#Reads in both Inputs for the Account ID OU Name and the OU Path for the enviroment
New-ADOrganizationalUnit -Name "$rwetd_name" -Path "OU=$rwetd_path,OU=Accounts,OU=AWS,DC=RWETD,DC=COM" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "$rwetd_name" -Path "OU=$rwetd_path,OU=Servers,OU=AWS,DC=RWETD,DC=COM" -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit -Name "$rwetd_name" -Path "OU=$rwetd_path,OU=Groups,OU=AWS,DC=RWETD,DC=COM" -ProtectedFromAccidentalDeletion $false
$ouname1 = "OU=$rwetd_name," + "OU=$rwetd_path,OU=Accounts,OU=AWS,DC=RWETD,DC=COM"
$ouname2 = "OU=$rwetd_name," + "OU=$rwetd_path,OU=Servers,OU=AWS,DC=RWETD,DC=COM"
$ouname3 = "OU=$rwetd_name," + "OU=$rwetd_path,OU=Groups,OU=AWS,DC=RWETD,DC=COM"

#Write-Host("You have entered an invalid OU Path name. Please run the script again!") -ForegroundColor Red -BackgroundColor Yellow



#Creates the Delegated Group OU dependant on the initial inputs
$dlgou = "OU=Groups,OU=Admin,OU=AWS,DC=RWETD,DC=COM"
If ($rwetd_path -eq "UAT") {
$newdlg = New-ADGroup "awsu-l-dlg-$rwetd_name" -Path $dlgou -GroupCategory Security -GroupScope DomainLocal -PassThru –Verbose
}
Elseif ($rwetd_path -eq "Prd") {
$newdlg = New-ADGroup "awsp-l-dlg-$rwetd_name" -Path $dlgou -GroupCategory Security -GroupScope DomainLocal -PassThru –Verbose
}
Elseif ($rwetd_path -eq "NoPrd") {
$newdlg = New-ADGroup "awsn-l-dlg-$rwetd_name" -Path $dlgou -GroupCategory Security -GroupScope DomainLocal -PassThru –Verbose
}

#Reads in the OU Names and Delegated Group from inputs
$ou1 = Get-ADOrganizationalUnit -Identity $ouname1 | Select-Object -ExpandProperty DistinguishedName
$ou2 = Get-ADOrganizationalUnit -Identity $ouname2 | Select-Object -ExpandProperty DistinguishedName
$ou3 = Get-ADOrganizationalUnit -Identity $ouname3 | Select-Object -ExpandProperty DistinguishedName
$group = Get-ADGroup $newdlg
#Creates a variable from the Delegated Group that can be used to apply permissions. .NET is parameters are used to achieve this
$sid = new-object System.Security.Principal.SecurityIdentifier $group.SID
#Reads in the ACL path for the OU's
$acl1 = get-acl -Path "$ou1"
$acl2 = get-acl -Path "$ou2"
$acl3 = get-acl -Path "$ou3"
#Schema GUID's read in for Computer, User and Group objects
$servers = [GUID]"bf967a86-0de6-11d0-a285-00aa003049e2"
$accounts = [GUID]"bf967aba-0de6-11d0-a285-00aa003049e2"
$groups = [GUID]"bf967a9c-0de6-11d0-a285-00aa003049e2"
#Permissions are declared for the Delegated Group against each Schema GUID type
$ace1 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild","Allow","Descendents", $accounts
$ace2 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"DeleteChild", "Allow","Descendents", $accounts
$ace3 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"WriteProperty", "Allow","Descendents", $accounts
$ace4 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild","Allow","Descendents", $servers
$ace5 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"DeleteChild", "Allow","Descendents", $servers
$ace6 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"CreateChild","Allow","Descendents", $groups
$ace7 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"DeleteChild", "Allow","Descendents", $groups
$ace8 = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,"WriteProperty", "Allow","Descendents", $groups
#Access rules mapped between OU's and Delegated Group
$acl1.AddAccessRule($ace1)
$acl1.AddAccessRule($ace2)
$acl1.AddAccessRule($ace3)
$acl2.AddAccessRule($ace4)
$acl2.AddAccessRule($ace5)
$acl3.AddAccessRule($ace6)
$acl3.AddAccessRule($ace7)
$acl3.AddAccessRule($ace8)
#Permissions applied to the relevant OU based on mapping above
set-acl -Path "$ou1" -AclObject $acl1
set-acl -Path "$ou2" -AclObject $acl2
set-acl -Path "$ou3" -AclObject $acl3
#Remove PSDrive
c:
Remove-PSDrive RWETD
Exit
}


#Main menu loop
do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
           '1' {
                cls
                LEO
           } '2' {
                cls
                RWETD
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')