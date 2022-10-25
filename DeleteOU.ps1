cls
Import-Module ActiveDirectory
Write-Host 'Enter LEO Domain Credentials' 
New-PSDrive LEO -PSProvider ActiveDirectory -Server "LEO.INFRA.COM" -Root "//RootDSE/" -Credential "" -Scope Global
cls
cd LEO:
#Reads in both Inputs for the Account ID OU Name and the OU Path for the enviroment
$leo_name = Read-Host -Prompt 'Input Name of the Account ID to be deleted'
$leo_path = Read-Host -Prompt 'Input which environment OU will be deleted for (NoPrd, Prd or UAT)'

#Creates the OU's in the correct locations depending on the inputs above
If ($leo_path -eq "UAT"){
Remove-ADOrganizationalUnit -Identity "OU=$leo_name,OU=UAT,OU=Accounts,OU=AWS,DC=LEO,DC=INFRA,DC=COM" -Confirm:$false
}
Elseif ($leo_path -eq "Prd"){
Remove-ADOrganizationalUnit -Identity "OU=$leo_name,OU=Prd,OU=Accounts,OU=AWS,DC=LEO,DC=INFRA,DC=COM" -Confirm:$false
}
Elseif ($leo_path -eq "NoPrd"){
Remove-ADOrganizationalUnit -Identity "OU=$leo_name,OU=NoPrd,OU=Accounts,OU=AWS,DC=LEO,DC=INFRA,DC=COM" -Confirm:$false
}
Else {
Write-Host("You have entered an invalid OU Path name. Please run the script again!") -ForegroundColor Red -BackgroundColor Yellow
#Remove PSDrive
c:
Remove-PSDrive LEO
Exit
}